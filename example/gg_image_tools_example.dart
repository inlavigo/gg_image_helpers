#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_image_tools/src/split/split.dart';

Future<void> main() async {
  final input = Directory('./test/images');
  final output = Directory.systemTemp.createTempSync();

  final ggImageTools = Split(
    input: input,
    output: output,
    log: print,
  );

  await ggImageTools.exec();

  print('Done.');
}
