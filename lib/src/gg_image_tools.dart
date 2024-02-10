// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'package:args/command_runner.dart';

/// Gg Image Tools
class GgImageTools {
  /// Constructor
  GgImageTools({
    required this.param,
    required this.log,
  });

  /// The param to work with
  final String param;

  /// The log function
  final void Function(String msg) log;

  /// The function to be executed
  Future<void> exec() async {
    log('Executing GgImageTools with param $param');
  }
}

// #############################################################################
/// The command line interface for GgImageTools
class GgImageToolsCmd extends Command<dynamic> {
  /// Constructor
  GgImageToolsCmd({required this.log}) {
    _addArgs();
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'ggImageTools';
  @override
  final description = 'Add your description here.';

  // ...........................................................................
  @override
  Future<void> run() async {
    var param = argResults?['param'] as String;
    GgImageTools(
      param: param,
      log: log,
    );

    await GgImageTools(
      param: param,
      log: log,
    ).exec();
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addOption(
      'param',
      abbr: 'p',
      help: 'The param to work with',
      valueHelp: 'param',
      defaultsTo: '.',
    );
  }
}
