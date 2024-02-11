// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_image_tools/src/split_image_folders_by_creation_date.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'expected_output_pathes.dart';

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
      for (final useBirthDate in [true, false]) {
        test(
            'should move images and videos with creation dates that match not '
            'the folder date to a new parent folder', () async {
          createOutputFolder();
          final move = SplitImageFoldersByCreationDate(
            input: input,
            output: output,
            log: (msg) {},
            useBirthDate: useBirthDate,
          );
          await move.exec();

          // The images have been moved to folders matching their creation date
          expectRightFilePathes(output: output, useBirthDate: useBirthDate);
        });
      }
    });

    // .........................................................................
    test('should throw if target folder already exists', () {
      createOutputFolder();
      output.createSync();

      expect(
        () {
          SplitImageFoldersByCreationDate(
            input: input,
            output: input, // Input and output are the same
            log: (msg) {},
          );
        },
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            'Exception: Target folder already exists',
          ),
        ),
      );
    });
  });
}
