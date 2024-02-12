// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// .............................................................................
import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:gg_image_tools/src/split/split_cli.dart';

/// Executes the GgImageTools command line interface
Future<void> ggImageToolsCli({
  required List<String> args,
  required void Function(String msg) log,
}) async {
  try {
    // Create a command runner
    final CommandRunner<void> runner = CommandRunner<void>(
      'GgImageTools',
      'Various tools for image organization. '
          'They help to organize folders with images. ',
    )

      /// Add more commands here
      ..addCommand(SplitCli(log: log));

    // Run the command
    await runner.run(args);
  }

  // Print errors in red
  catch (e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    log(Colorize(msg).red().toString());
    log('Error: $e');
  }
}
