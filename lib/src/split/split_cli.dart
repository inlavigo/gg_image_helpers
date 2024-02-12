// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_image_tools/src/split/split.dart';

/// The command line interface for GgImageTools
class SplitCli extends Command<dynamic> {
  /// Constructor
  SplitCli({required this.log}) {
    _addArgs();
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'split';
  @override
  final description =
      'Move images to the folders prefixed with their creation date';

  // ...........................................................................
  @override
  Future<void> run() async {
    var input = argResults?['input'] as String;
    var output = argResults?['output'] as String;

    var inputDir = Directory(input);
    var outputDir = Directory(output);

    final move = Split(
      input: inputDir,
      output: outputDir,
      log: log,
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
  }
}
