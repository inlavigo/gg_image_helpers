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
  final parentDir = Directory(join(tempDir.path, 'move_images_test'));
  final imageDir01 = Directory(join(parentDir.path, '2024-02-10 Vacation'));
  final imageDir02 = Directory(join(parentDir.path, '2024-02-12 Holiday'));
  final imageDir03 = Directory(join(parentDir.path, '2023-08-05 Summer Time'));

  // ...........................................................................
  void createTestFolders() {
    // Delete previous folder
    if (parentDir.existsSync()) {
      parentDir.deleteSync(recursive: true);
    }

    // Create new parent directory
    parentDir.createSync(recursive: true);

    // Create three image directories
    imageDir01.createSync(recursive: true);
    imageDir02.createSync(recursive: true);
    imageDir03.createSync(recursive: true);

    // Copy sample images into the directories
    final sampleImageDir = Directory('./test/images');
    assert(sampleImageDir.existsSync());
    for (final image in sampleImageDir.listSync().whereType<File>()) {
      final targetFilePath = join(imageDir01.path, basename(image.path));
      image.copySync(targetFilePath);
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
        createTestFolders();
        final move = MoveImagesWithWrongDate(path: parentDir.path);
        await move.exec();
      });
    });
  });
}
