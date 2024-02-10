#!/usr/bin/env dart

import 'dart:io';
import 'package:yaml/yaml.dart';

import 'package:args/args.dart';

// ######################
// Helpers
// ######################

var isGitHub = Platform.environment.containsKey('GITHUB_ACTIONS');
var hasErrors = false;
var verbose = true;
var printAnnouncement = !isGitHub;
final errorMessages = <String>[];
dynamic yaml;

// .............................................................................
void loadConfig() {
  var file = File('check.yaml');
  if (!file.existsSync()) {
    print('❌ check.yaml not found');
    exit(1);
  }

  yaml = loadYaml(file.readAsStringSync());
}

// .............................................................................
bool shouldExecute({required String name}) {
  if (yaml[name] == null) {
    print('❌ $name not found in check.yaml. '
        'Please add configuration for it.');
    exit(1);
  }

  if (yaml[name]['execute'] == null) {
    print('❌ $name does not have an "execute:" section. '
        'Please open check.yaml and add it to the "$name" section.');
    exit(1);
  }

  return yaml[name]['execute'] == null || yaml[name]['execute'] == true;
}

// .............................................................................
void printResult({
  required String message,
  required bool success,
}) {
  var carriageReturn = printAnnouncement ? '\x1b[1A\x1b[2K' : '';
  var icon = success ? '✅' : '❌';
  print('$carriageReturn$icon $message');
}

// .............................................................................
Future<bool> check({
  required String name,
  required String command,
  String? message,
}) async {
  if (!shouldExecute(name: name)) {
    return true;
  }

  if (printAnnouncement) print('⌛️ $message');
  final parts = command.split(' ');
  final cmd = parts.first;
  final List<String> arguments = parts.length > 1 ? parts.sublist(1) : [];
  final result = await Process.run(cmd, arguments);
  final success = result.exitCode == 0;

  printResult(message: message ?? cmd, success: result.exitCode == 0);

  if (!success) {
    hasErrors = true;
    if (verbose) {
      print(result.stdout.toString());
      print(result.stderr.toString());
    }
  }
  return success;
}

// .............................................................................
void parseArgs(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('verbose', negatable: false, abbr: 'v')
    ..addFlag(
      'help',
      negatable: false,
      abbr: 'h',
      help: 'Displays this help information.',
    );

  var argResults = parser.parse(arguments);

  if (argResults['help'] == true) {
    print('Usage: dart your_script.dart [options]');
    print(parser.usage);
    exit(0);
  }

  verbose = argResults['verbose'] == true;
}

// ######################
// Main
// ######################

// .............................................................................
Future<int> main(List<String> arguments) async {
  parseArgs(arguments);
  loadConfig();
  print('');

  await check(
    name: 'analyze',
    command: 'dart analyze --fatal-infos --fatal-warnings',
    message: 'dart analyze',
  );

  await check(
    name: 'format',
    command: 'dart format lib --output=none --set-exit-if-changed',
    message: 'dart format',
  );

  await check(
    name: 'coverage',
    command: 'dart check_coverage.dart',
    message: 'dart check_coverage.dart',
  );

  await check(
    name: 'pana',
    command: 'dart ./check_pana.dart',
    message: 'dart run pana',
  );

  final resultMessage = hasErrors
      ? 'Errors found. '
          'Run the failed commands above and, fix the errors and try again.'
      : '🤩 Everything is fine!';

  print('');
  print(resultMessage);
  print('');
  exit(hasErrors ? 1 : 0);
}
