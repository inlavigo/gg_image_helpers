// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:exif/exif.dart';
import 'package:path/path.dart';

/// MoveImagesWithWrongDate
class MoveImagesWithWrongDate {
  /// The file types that are processed
  static const supportedFileTypes = [
    'jpg',
    'jpeg',
    'bpm',
    'png',
    'heic',
    'mp4',
    'mov',
  ];

  /// Constructor
  MoveImagesWithWrongDate({
    required this.input,
    required this.output,
    required this.log,
  }) {
    assert(input.existsSync());
    assert(output.existsSync());
    assert(input.absolute != output.absolute);
  }

  /// The input folder the images are read from
  final Directory input;

  /// The output folder the images are copied to
  final Directory output;

  /// The log function
  void Function(String msg) log;

  // ...........................................................................
  /// Execute process
  Future<void> exec() async {
    // Get all folders in folder
    final subFolders = input.listSync().whereType<Directory>();
    for (final Directory folder in subFolders) {
      await _processFolder(folder);
    }
  }

  // ...........................................................................
  Future<void> _processFolder(Directory folder) async {
    // Get base name
    final folderName = basename(folder.path);

    // Extract prefix yyyy-mm-dd from folder name?
    final regExp = RegExp(r'^(\d\d\d\d)-(\d\d)-(\d\d)');
    final firstMatch = regExp.firstMatch(folderName);

    // No image folder?
    if (firstMatch == null) {
      return;
    }

    // Get dates
    final year = int.parse(firstMatch.group(1)!);
    final month = int.parse(firstMatch.group(2)!);
    final day = int.parse(firstMatch.group(3)!);

    // Iterate all images
    final images = folder.listSync().whereType<File>().where((element) {
      var ext = extension(element.path.toLowerCase());
      ext = ext.substring(1, ext.length);

      final result = supportedFileTypes.contains(
        ext,
      );
      return result;
    });

    for (final image in images) {
      await _processImage(
        image: image,
        year: year,
        month: month,
        day: day,
      );
    }

    // Delete folder if it is empty
    if (folder.listSync().isEmpty) {
      folder.deleteSync();
    }
  }

  // ...........................................................................
  Future<DateTime> _fileCreationDate(File image) async {
    final fileStat = await image.stat();
    return fileStat.changed;
  }

  // ...........................................................................
  Future<DateTime?> _exifCreationDate(File image) async {
    // Get exif data
    final bytes = await image.readAsBytes();
    final data = await readExifFromBytes(bytes);

    // Get creation date
    final creationDate = data['Image DateTime'];
    if (creationDate == null) {
      return null;
    }

    // Parse creation date
    // Replace ':' with '-' in the date portion and add 'T' before the time
    String isoDateString = creationDate.toString();
    final parts = isoDateString.split(' ');
    final date = parts[0].replaceAll(':', '-');
    final time = parts[1];

    // Now, you can parse it into a DateTime object
    DateTime dateTime = DateTime.parse([date, time].join(' '));

    return dateTime;
  }

  // ...........................................................................
  Future<void> _processImage({
    required File image,
    required int year,
    required int month,
    required int day,
  }) async {
    final creationDate =
        await _exifCreationDate(image) ?? await _fileCreationDate(image);

    // Does the creation date of the image match the folder date?
    final DateTime(year: yearIs, month: monthIs, day: dayIs) = creationDate;

    // If no, create a folder with that date
    final imageFolder = image.parent;

    // Extract the name from the imageFolder
    final name =
        basename(imageFolder.path).substring('YYYY-MM-DD'.length).trim();

    // Create the target folder with the right date
    final yearStr = yearIs.toString();
    final monthStr = monthIs.toString().padLeft(2, '0');
    final dayStr = dayIs.toString().padLeft(2, '0');
    final folderName = '$yearStr-$monthStr-$dayStr $name';

    // Create folder when not existing
    final targetFolder = Directory(join(output.path, folderName));
    if (!targetFolder.existsSync()) {
      targetFolder.createSync();
    }

    // Copy the to that folder
    final newFilePath = join(targetFolder.path, basename(image.path));
    image.copySync(newFilePath);
  }
}
