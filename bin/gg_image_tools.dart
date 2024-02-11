#!/usr/bin/env dart

// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.
import 'package:gg_image_tools/src/run_gg_image_tools.dart';

// .............................................................................
Future<void> main(List<String> args) async {
  await runGgImageTools(
    args: args,
    log: (msg) => print(msg),
  );
}
