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
    assert(input.absolute != output.absolute);
    if (output.existsSync()) {
      throw Exception('Target folder already exists');
    }
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
    output.createSync(recursive: true);

    // Iterate all images
    final images =
        input.listSync(recursive: true).whereType<File>().where((element) {
      var ext = extension(element.path.toLowerCase());
      ext = ext.substring(1, ext.length);

      final isImage = supportedFileTypes.contains(ext);
      return isImage;
    });

    for (final image in images) {
      await _processImage(
        image: image,
      );
    }
  }

  // ...........................................................................
  Future<DateTime> _fileCreationDate(File image) async {
    final fileStat = await image.stat();
    var result = fileStat.changed;
    if (result.microsecondsSinceEpoch >
        fileStat.modified.microsecondsSinceEpoch) result = fileStat.modified;

    if (result.microsecondsSinceEpoch >
        fileStat.accessed.microsecondsSinceEpoch) {
      result = fileStat.accessed;
    }

    return result;
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
  }) async {
    final creationDate =
        await _exifCreationDate(image) ?? await _fileCreationDate(image);

    // Does the creation date of the image match the folder date?
    final DateTime(year: yearIs, month: monthIs, day: dayIs) = creationDate;

    // If no, create a folder with that date
    final imageFolder = image.parent;

    // Remove date from image folder
    final name = basename(imageFolder.path)
        .replaceFirst(RegExp(r'^\d\d\d\d-\d\d-\d\d '), '');

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
