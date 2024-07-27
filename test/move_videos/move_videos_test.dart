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
  final original = Directory('./test/test_images');
  final input = Directory(tempDir.path).createTempSync();
  final target = Directory(tempDir.path).createTempSync();

  // ...........................................................................
  void createOutputFolder() {
    // Delete previous folder
    if (target.existsSync()) {
      target.deleteSync(recursive: true);
    }
  }

  // ...........................................................................
  tearDown(() async {
    // Delete input folder
    if (await input.exists()) {
      await input.delete(recursive: true);
    }
  });

  group('MoveVideos', () {
    test('should be able to write to temp directory', () {
      expect(tempDir.existsSync(), isTrue);
      final sampleFilePath = join(tempDir.path, 'jd08420.txt');
      File(sampleFilePath).writeAsStringSync('Hello');
    });

    // #########################################################################
    group('exec()', () {
      // .......................................................................

      group('should move videos to the output folder', () {
        for (final dryRun in [true, false]) {
          test('with dryRun == $dryRun', () async {
            // Copy test images to input folder
            original.listSync(recursive: true).forEach((element) {
              if (element is File) {
                final targetPath = element.path.replaceAll(
                  original.path,
                  input.path,
                );

                final targetFolder = Directory(dirname(targetPath));
                if (targetFolder.existsSync() == false) {
                  targetFolder.createSync(recursive: true);
                }

                element.copySync(targetPath);
              }
            });

            // Define video pathes
            final originalVideoPath =
                join(input.path, '2024-02-10 Images', 'flower.mov');
            final targetVideoPath =
                join(target.path, '2024-02-10 Images', 'flower.mov');

            // Is video yet in input folder
            expect(File(originalVideoPath).existsSync(), isTrue);

            // Create output folder
            createOutputFolder();

            // Execute
            final messages = <String>[];
            final split = MoveVideos(
              input: input,
              output: target,
              dryRun: dryRun,
              log: messages.add,
            );
            await split.exec();

            // Did create target folder?
            expect(target.existsSync(), dryRun ? isFalse : isTrue);

            // Did copy video to target folder?
            expect(
              await File(targetVideoPath).exists(),
              dryRun ? isFalse : isTrue,
            );

            // Did delete video from input folder?
            expect(
              await File(originalVideoPath).exists(),
              dryRun ? isTrue : isFalse,
            );

            // Did log the result?
            expect(messages[0], 'Move $originalVideoPath to $targetVideoPath');
          });
        }
      });
    });

    // .........................................................................
    test('should throw if target folder exists', () {
      createOutputFolder();
      target.createSync();

      expect(
        () {
          MoveVideos(
            input: original,
            output: original, // Input and output are the same
            dryRun: false,
            log: (msg) {},
          );
        },
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'toString',
            contains('Target folder already exists'),
          ),
        ),
      );
    });
  });
}
