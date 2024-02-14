// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:test/test.dart';

// ...........................................................................
final gitHubTmpPath = Platform.environment['RUNNER_TEMP'];
final gitHubTmp = gitHubTmpPath != null ? Directory(gitHubTmpPath!) : null;
final slashTmp = Directory('/tmp').existsSync() ? Directory('/tmp') : null;
final systemTmp = Directory.systemTemp;
final isApple = Platform.isMacOS || Platform.isIOS;
final tempDir = gitHubTmp ?? slashTmp ?? systemTmp;

// ...........................................................................
void expectRightFilePathes({
  required Directory output,
}) {
  final outputPath = output.path;
  final expectedFiles = _expectedOutputImagePathes(
    outputPath: outputPath,
  );

  for (final path in expectedFiles) {
    expect(File(path).existsSync(), isTrue, reason: 'File not found: $path');
  }
}

// .............................................................................
List<String> _expectedOutputImagePathes({
  required String outputPath,
}) =>
    [
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

      // 2023-03-12
      if (Platform.isMacOS || Platform.isIOS)
        '$outputPath/2022-03-12 Images/flower.mov',
    ];
