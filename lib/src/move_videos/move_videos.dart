// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:path/path.dart';

/// MoveImagesWithWrongDate
class MoveVideos {
  /// The file types that are processed
  static const videoFileTypes = [
    'mp4',
    'mov',
  ];

  /// Constructor
  MoveVideos({
    required this.input,
    required this.output,
    required this.log,
    required this.dryRun,
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

  /// Dry run
  final bool dryRun;

  /// The log function
  void Function(String msg) log;

  // ...........................................................................
  /// Execute process
  Future<void> exec() async {
    if (!dryRun) {
      output.createSync(recursive: true);
    }

    // Iterate all videos
    final videos =
        input.listSync(recursive: true).whereType<File>().where((element) {
      var ext = extension(element.path.toLowerCase());
      if (ext.isEmpty) {
        return false;
      }

      ext = ext.substring(1, ext.length);

      final isImage = videoFileTypes.contains(ext);
      return isImage;
    });

    for (final video in videos) {
      await _processVideo(
        video: video,
      );
    }

    log('Done.');
  }

  // ...........................................................................
  Future<void> _processVideo({
    required File video,
  }) async {
    // Get the relative path of the video from input folder
    final relativeImagePath = video.path.substring(input.path.length + 1);
    final relativeFolderPath = dirname(relativeImagePath);

    // Calculate the target folder
    final folderName = join(output.path, relativeFolderPath);
    final targetFolder = Directory(join(output.path, folderName));
    if (!targetFolder.existsSync()) {
      if (!dryRun) {
        targetFolder.createSync();
      }
    }

    // Move the video to that folder
    final newFilePath = join(targetFolder.path, basename(video.path));

    if (!dryRun) {
      video.renameSync(newFilePath);
    }

    log('Move ${video.path} to $newFilePath');
  }
}
