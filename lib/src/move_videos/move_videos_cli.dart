// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_image_tools/gg_image_tools.dart';

/// The command line interface for GgImageTools
class MoveVideosCli extends Command<dynamic> {
  /// Constructor
  MoveVideosCli({required this.log}) {
    _addArgs();
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'moveVideos';
  @override
  final description = 'Move videos in the folders to a separate folder';

  // ...........................................................................
  @override
  Future<void> run() async {
    final input = argResults?['input'] as String;
    final output = argResults?['output'] as String;
    final dryRun = argResults?['dry-run'] as bool;

    final inputDir = Directory(input);
    final outputDir = Directory(output);

    final move = MoveVideos(
      input: inputDir,
      output: outputDir,
      log: log,
      dryRun: dryRun,
    );

    await move.exec();
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'input',
      abbr: 'i',
      help: 'The folder where the image folders are located',
      valueHelp: 'Input folder',
      mandatory: true,
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'The folder where the cleaned up images should be written to.',
      valueHelp: 'Input folder',
      mandatory: true,
    );

    // Add dry run option
    argParser.addFlag(
      'dry-run',
      abbr: 'd',
      help: 'Do not move the files, just print the actions',
      negatable: false,
      defaultsTo: false,
    );
  }
}
