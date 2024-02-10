// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_image_tools/gg_image_tools.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  group('GgImageTools()', () {
    // #########################################################################
    group('MoveImagesWithWrongDate', () {
      test('should allow to run the code from command line', () async {
        final ggImageTools =
            MoveImagesWithWrongDateCmd(log: (msg) => messages.add(msg));

        final CommandRunner<void> runner = CommandRunner<void>(
          'ggImageTools',
          'Description goes here.',
        )..addCommand(ggImageTools);

        // await runner.run(['ggImageTools', '--param', 'foo']);
      });
    });
  });
}
