// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:exif/exif.dart';
import 'package:path/path.dart';

/// MoveImagesWithWrongDate
class Split {
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
  Split({
    required this.input,
    required this.output,
    required this.log,
  }) {
    assert(input.existsSync());
    assert(input.absolute != output.absolute);
    if (output.existsSync()) {
      throw ArgumentError('Target folder already exists');
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
      if (ext.isEmpty) {
        return false;
      }

      ext = ext.substring(1, ext.length);

      final isImage = supportedFileTypes.contains(ext);
      return isImage;
    });

    for (final image in images) {
      await _processImage(
        image: image,
      );
    }

    log('Done.');
  }

  // ...........................................................................
  // coverage:ignore-start
  Future<DateTime?> _getFileCreationDate(String filePath) async {
    // macOS 'stat' command to get file details, including the creation date.
    // The '-f' flag specifies the output format, '%B' gets the birth time of
    // the file.
    var result = await Process.run('stat', ['-f', '%B', filePath]);

    if (result.exitCode == 0) {
      // The output will be the creation date as a timestamp.
      var timestamp = int.parse((result.stdout as String).trim());
      var creationDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return creationDate;
    }
    return null;
  }
  // coverage:ignore-end

  // ...........................................................................
  Future<DateTime> _fileCreationDate(File image) async {
    // coverage:ignore-start
    bool useBirthDate = (Platform.isMacOS || Platform.isIOS);
    var result = useBirthDate ? await _getFileCreationDate(image.path) : null;
    if (result != null) {
      return result;
    }

    final fileStat = await image.stat();
    result = fileStat.accessed;
    if (result.microsecondsSinceEpoch >
        fileStat.changed.microsecondsSinceEpoch) {
      result = fileStat.changed;
    }

    if (result.microsecondsSinceEpoch >
        fileStat.modified.microsecondsSinceEpoch) {
      result = fileStat.modified;
    }

    return result;
    // coverage:ignore-end
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
