// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_image_tools/src/./move_images_with_wrong_date.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  final tempDir =
      Directory('/tmp').existsSync() ? Directory('/tmp') : Directory.systemTemp;
  final output = Directory(join(tempDir.path, 'move_images_test'));
  final input = Directory('./test/test_images/2024-02-10 Images');

  // ...........................................................................
  void createOutputFolder() {
    // Delete previous folder
    if (output.existsSync()) {
      output.deleteSync(recursive: true);
    }
  }

  group('MoveImagesWithWrongDate', () {
    // #########################################################################
    group('exec()', () {
      // .......................................................................
      test(
          'should move images with creation dates '
          'that match not the folder date '
          'to a new parent folder', () async {
        createOutputFolder();
        final move = MoveImagesWithWrongDate(
          input: input,
          output: output,
          log: (msg) {},
        );
        await move.exec();

        // The images have been moved to folders matching their creation date
        final outputPath = output.path;
        final expectedFiles = [
          // 2023-07-06
          '$outputPath/2023-07-06 Images/_DSC0004.JPG',
          '$outputPath/2023-07-06 Images/_DSC0006.JPG',
          '$outputPath/2023-07-06 Images/_DSC0012.JPG',
          '$outputPath/2023-07-06 Images/_DSC0017.JPG',
          // 2023-09-10
          '$outputPath/2023-09-10 Images/IMG_7898.HEIC',
          // 2023-09-14
          '$outputPath/2023-09-14 Images/IMG_7900.HEIC',
          // 2023-09-17
          '$outputPath/2023-09-17 Images/IMG_7957.HEIC',
          '$outputPath/2023-09-17 Images/IMG_7958.HEIC',
        ];

        for (final path in expectedFiles) {
          expect(File(path).existsSync(), isTrue);
        }
      });
    });
  });
}
