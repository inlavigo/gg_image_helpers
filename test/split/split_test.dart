// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_image_tools/gg_image_tools.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  final input = Directory('./test/test_images/2024-02-10 Images');
  final target = Directory(tempDir.path).createTempSync();

  // ...........................................................................
  void createOutputFolder() {
    // Delete previous folder
    if (target.existsSync()) {
      target.deleteSync(recursive: true);
    }
  }

  group('MoveImagesWithWrongDate', () {
    test('should be able to write to temp directory', () {
      expect(tempDir.existsSync(), isTrue);
      final sampleFilePath = join(tempDir.path, 'jd08420.txt');
      File(sampleFilePath).writeAsStringSync('Hello');
    });

    // #########################################################################
    group('exec()', () {
      // .......................................................................

      test(
          'should move images and videos with creation dates that match not '
          'the folder date to a new parent folder', () async {
        createOutputFolder();
        final split = Split(
          input: input,
          output: target,
          log: (msg) {},
        );
        await split.exec();

        // The images have been moved to folders matching their creation date
        expectRightFilePathes(output: target);
      });
    });

    // .........................................................................
    test('should throw if target folder already exists', () {
      createOutputFolder();
      target.createSync();

      expect(
        () {
          Split(
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
