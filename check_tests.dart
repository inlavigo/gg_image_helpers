#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:colorize/colorize.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';

// .............................................................................
bool isFlutterPackage() {
  final File pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw Exception('pubspec.yaml not found');
  }

  final String content = pubspec.readAsStringSync();
  return (content.contains('flutter'));
}

// .............................................................................
List<String> _extractErrorLines(String message) {
  // Regular expression to match file paths and line numbers
  RegExp exp = RegExp(r'test\/[\/\w]+\.dart[\s:]*\d+:\d+');
  final matches = exp.allMatches(message);
  final result = <String>[];

  if (matches.isEmpty) {
    return result;
  }

  for (final match in matches) {
    var matchedString = match.group(0) ?? '';
    result.add(matchedString);
  }

  return result;
}

// .............................................................................
String _makeErrorLineVscodeCompatible(String errorLine) {
  var parts = errorLine.split(' ');
  var filePath = parts[0];
  var lineInfo = parts[1].split(':');
  var lineNumber = lineInfo[0];
  var columnNumber = lineInfo[1];

  return '$filePath:$lineNumber:$columnNumber';
}

// .............................................................................
String makeErrorLinesInMessageVscodeCompatible(String message) {
  var errorLines = _extractErrorLines(message);
  var result = message;

  for (var errorLine in errorLines) {
    var compatibleErrorLine = _makeErrorLineVscodeCompatible(errorLine);
    result = result.replaceAll(errorLine, compatibleErrorLine);
  }

  return result;
}

// .............................................................................
typedef _Report = Map<String, Map<int, int>>;
typedef _MissingLines = Map<String, List<int>>;

// .............................................................................
_Report _generateReport() {
  // Iterate all 'dart.vm.json' files within coverage directory
  final coverageDir = Directory('./coverage');
  final coverageFiles =
      coverageDir.listSync(recursive: true).whereType<File>().where((file) {
    return file.path.endsWith('dart.vm.json');
  });

  // Prepare result
  final result = _Report();

  // Collect coverage data
  for (final coverageFile in coverageFiles) {
    final testFile = coverageFile.path
        .replaceAll('.vm.json', '')
        .replaceAll('./coverage/', '');
    final implementationFile = testFile
        .replaceAll('test/', 'lib/src/')
        .replaceAll('_test.dart', '.dart');
    final implementationFileWithoutLib =
        implementationFile.replaceAll('lib/', '');

    final fileContent = coverageFile.readAsStringSync();
    final coverageData = jsonDecode(fileContent);

    // Iterate coverage data
    final entries = coverageData['coverage'] as List<dynamic>;
    final entriesForImplementationFile = entries.where((entry) {
      final source = entry['source'] as String;
      return (source.contains(implementationFileWithoutLib));
    });
    for (final entry in entriesForImplementationFile) {
      // Read script

      // Find or create summary for script
      result[implementationFile] ??= {};
      late Map<int, int> summaryForScript = result[implementationFile]!;
      final ignoredLines = _ignoredLines(implementationFile);

      // Collect hits for all lines
      var hits = entry['hits'] as List<dynamic>;
      for (var i = 0; i < hits.length; i += 2) {
        final line = hits[i] as int;
        final isIgnored = ignoredLines[line];
        if (isIgnored) continue;
        final hitCount = hits[i + 1] as int;
        // Find or create summary for line
        final existingHits = summaryForScript[line] ?? 0;
        summaryForScript[line] = existingHits + hitCount;
      }
    }
  }

  return result;
}

// .............................................................................
double _calculateCoverage(_Report report) {
  // Calculate coverage
  var totalLines = 0;
  var coveredLines = 0;
  for (final script in report.keys) {
    for (final line in report[script]!.keys) {
      totalLines++;
      if (report[script]![line]! > 0) {
        coveredLines++;
      }
    }
  }

  // Calculate percentage
  var percentage = (coveredLines / totalLines) * 100;
  return percentage;
}

// .............................................................................
Map<String, List<bool>> _ignoredLinesCache = {};

// .............................................................................
List<bool> _ignoredLines(String script) {
  final cachedResult = _ignoredLinesCache[script];
  if (cachedResult != null) {
    return cachedResult;
  }

  // Return when line is in between coverag:ignore-start and coverage:ignore-end
  final lines = File(script).readAsLinesSync();
  final ignoredLines = List<bool>.filled(lines.length + 1, false);

  // Evaluate ignore start/end
  var ignoreStart = false;
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    var lineNumber = i + 1;

    // Whole file ignored?
    if (line.contains('coverage:ignore-file')) {
      ignoredLines.fillRange(0, lines.length + 1, true);
      break;
    }

    // Range ignored?
    if (line.contains('coverage:ignore-start')) {
      ignoreStart = true;
    }

    if (line.contains('coverage:ignore-end')) {
      ignoreStart = false;
    }

    // Line ignored?
    var ignoreLine = line.contains('coverage:ignore-line');
    if (ignoreLine) {
      print('Ignoring line: $line');
    }

    ignoredLines[lineNumber] = ignoreStart || ignoreLine;
  }

  _ignoredLinesCache[script] = ignoredLines;
  return ignoredLines;
}

// .............................................................................
_MissingLines _estimateMissingLines(_Report report) {
  final _MissingLines result = {};
  for (final script in report.keys) {
    final lines = report[script]!;
    final linesSorted = lines.keys.toList()..sort();

    for (final line in linesSorted) {
      final hits = lines[line]!;
      if (hits == 0) {
        result[script] ??= [];
        result[script]!.add(line);
      }
    }
  }

  return result;
}

// .............................................................................
void _printMissingLines(_MissingLines missingLines) {
  var lastUncoveredLine = -1;

  for (final script in missingLines.keys) {
    final testFile = script
        .replaceFirst('lib/src', 'test')
        .replaceAll('.dart', '_test.dart');
    final lineNumbers = missingLines[script]!;
    for (final lineNumber in lineNumbers) {
      // Dont print too many lines
      if (lineNumber - lastUncoveredLine >= 2) {
        final message = '$script:$lineNumber';
        print('- ${Colorize(message).red()}');
        print('  ${Colorize(testFile).blue()}\n');
      }

      lastUncoveredLine = lineNumber;
    }
  }
}

// .............................................................................
void _writeLcovReport(_Report report) {
  final buffer = StringBuffer();
  for (final script in report.keys) {
    buffer.writeln('SF:$script');
    for (final line in report[script]!.keys) {
      final hits = report[script]![line]!;
      buffer.writeln('DA:$line,$hits');
    }
    buffer.writeln('end_of_record');
  }

  final lcovReport = buffer.toString();
  final lcovFile = File('./coverage/lcov.info');
  lcovFile.writeAsStringSync(lcovReport);
}

// .............................................................................
List<(String, String)> _collectMissingTestFiles() {
  // Collect implementation files without test files
  final missingFiles = <(String, String)>[];

  // Get all implementation files
  final implementationFiles = Directory('./lib/src')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) {
    return file.path.endsWith('.dart');
  });

  // Find missing test files
  for (final implementationFile in implementationFiles) {
    final testFile = implementationFile.path
        .replaceAll('lib/src/', 'test/')
        .replaceAll('.dart', '_test.dart');

    if (!File(testFile).existsSync()) {
      missingFiles.add((implementationFile.path, testFile));
    }
  }

  return missingFiles;
}

// .............................................................................
const testBoilerplate = '''
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:test/test.dart';

void main() {
  group('Boilerplate', () {
    test('should work fine', () {
      // INSTANTIATE CLASS HERE
      expect(true, isNotNull);
    });
  });
}
''';

// .............................................................................
void _createMissingTestFiles(List<(String, String)> missingFiles) {
  // Create missing test files and ask user to edit it
  print(Colorize('Tests were. Please revise:').yellow());
  final packageName = basename(Directory.current.path);

  for (final (implementationFile, testFile) in missingFiles) {
    // Create test file with intermediate directories
    final testFileDir = dirname(testFile);
    Directory(testFileDir).createSync(recursive: true);

    // Write boilerplate
    final className = basenameWithoutExtension(implementationFile).pascalCase;

    final implementationFilePath =
        implementationFile.replaceAll('lib/', '').replaceAll('./', '');

    final boilerplate = testBoilerplate
        .replaceAll('Boilerplate', className)
        .replaceAll('// INSTANTIATE CLASS HERE', 'const $className();')
        .replaceAll(
          'import \'package:test/test.dart\';',
          'import \'package:$packageName/'
              // ignore: missing_whitespace_between_adjacent_strings
              '$implementationFilePath\';\n'
              'import \'package:test/test.dart\';\n',
        );

    // Create boilerplate file
    File(testFile).writeAsStringSync(boilerplate);

    // Print message
    print('- ${Colorize(implementationFile).red()}');
    print('- ${Colorize(testFile).blue()}');
  }
}

// .............................................................................
Future<int> test() async {
  // Remove the coverage directory
  var coverageDir = Directory('coverage');
  if (coverageDir.existsSync()) {
    coverageDir.deleteSync(recursive: true);
  }

  // Run the Dart coverage command

  var errorLines = <String>{};
  var previousMessagesBelongingToError = <String>[];
  var isError = false;

  var process = isFlutterPackage()
      ? await Process.start(
          'flutter',
          ['test', '--coverage'],
        )
      : await Process.start(
          'dart',
          [
            'test',
            '-r',
            'expanded',
            '--coverage',
            'coverage',
            '--chain-stack-traces',
            '--no-color',
          ],
        );

  // Iterate over stdout and print output using a for loop
  await for (var event in process.stdout.transform(utf8.decoder)) {
    isError = isError || event.contains('[E]');
    if (isError) {
      event = makeErrorLinesInMessageVscodeCompatible(event);
      previousMessagesBelongingToError.add(event);
    }

    final newErrorLines = _extractErrorLines(event);
    if (newErrorLines.isNotEmpty && !errorLines.contains(newErrorLines.first)) {
      // Print error line

      final newErrorLinesString = newErrorLines.join(',\n   ');
      print(Colorize(' - $newErrorLinesString').red().toString());

      // Print messages belonging to this error
      for (var message in previousMessagesBelongingToError) {
        print(Colorize(message).darkGray().toString());
      }

      isError = false;
    }
    errorLines.addAll(newErrorLines);
  }

  return process.exitCode;
}

// .............................................................................
Future<void> main(List<String> arguments) async {
  // Check if test files are missing for implemenation files
  final missingTestFiles = _collectMissingTestFiles();
  if (missingTestFiles.isNotEmpty) {
    _createMissingTestFiles(missingTestFiles);
    exit(1);
  }

  // Run Tests
  final error = await test();
  if (error != 0) {
    exit(error);
  }

  // Generate coverage reports
  final report = _generateReport();
  var percentage = _calculateCoverage(report);
  _writeLcovReport(report);

  // Check coverage percentage
  if (percentage != 100.0) {
    // Print percentage
    print(
      Colorize('Coverage not 100%. Untested code:').yellow(),
    );

    // Print missing lines
    final missingLines =
        percentage < 100.0 ? _estimateMissingLines(report) : _MissingLines();

    _printMissingLines(missingLines);

    exit(1);
  } else {
    print('✅ Coverage is 100%!');
    exit(0);
  }
}
