import 'dart:io';

import '../../utils/project.dart';
import '../../utils/utils.dart';
import '../../version.dart';

/// `river_cli doctor` — a one-shot health check of the current Flutter project:
/// SDK availability, project metadata, installed modules, key dependencies,
/// scaffolded features, and whether the Claude Code skill is installed.
void runDoctor() {
  print('river_cli doctor (v$kRiverCliVersion)\n');

  var problems = 0;
  void ok(String msg) => print('  ✓ $msg');
  void warn(String msg) {
    print('  ! $msg');
    problems++;
  }

  void fail(String msg) {
    print('  ✗ $msg');
    problems++;
  }

  // --- Environment ---
  print('Environment');
  if (Utils.isFlutterAvailable()) {
    ok('Flutter is on PATH');
  } else {
    warn('Flutter not found on PATH (package versions cannot auto-resolve)');
  }

  if (!ProjectContext.isFlutterRoot) {
    fail('pubspec.yaml not found — run inside a Flutter project root');
    print('\nFound $problems issue(s).');
    exit(1);
  }
  ok('pubspec.yaml found');

  final ctx = ProjectContext.detect();
  print('\nProject');
  if (ctx.packageName != null) {
    ok('package: ${ctx.packageName}');
  } else {
    warn('could not read package name from pubspec.yaml');
  }

  // --- Modules ---
  print('\nModules installed');
  final modules = <String, bool>{
    'config': ctx.hasConfig,
    'utils': ctx.hasUtils,
    'extensions': ctx.hasExtensions,
    'widgets': ctx.hasWidgets,
    'network': ctx.hasNetwork,
    'storage': ctx.hasStorage,
  };
  final anyModule = modules.values.any((v) => v);
  if (!anyModule) {
    warn('no river_cli modules detected — run "river_cli init" to scaffold');
  } else {
    modules.forEach((key, present) {
      print('  ${present ? '✓' : '·'} $key');
    });
  }

  // --- Core dependencies ---
  print('\nCore dependencies');
  final pubspec = File('pubspec.yaml').readAsStringSync();
  for (final dep in ['flutter_riverpod', 'go_router']) {
    if (RegExp('^\\s+$dep:', multiLine: true).hasMatch(pubspec)) {
      ok('$dep present');
    } else {
      warn('$dep missing from pubspec.yaml');
    }
  }

  // --- Routing ---
  print('\nRouting');
  if (File('lib/app/routes/route_page.dart').existsSync()) {
    ok('go_router config found (lib/app/routes/route_page.dart)');
  } else {
    warn('no routing file yet — created on first "river_cli create page:"');
  }

  // --- Features ---
  print('\nFeatures');
  final features = ProjectContext.findFeatures();
  if (features.isEmpty) {
    print('  · none scaffolded yet');
  } else {
    for (final f in features) {
      print('  ✓ $f');
    }
  }

  // --- Claude Code skill ---
  print('\nClaude Code skill');
  final localSkill =
      File('.claude/skills/river-cli-flutter/SKILL.md').existsSync();
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  final globalSkill = home != null &&
      File('$home/.claude/skills/river-cli-flutter/SKILL.md').existsSync();
  if (localSkill) {
    ok('installed in this project (.claude/skills/river-cli-flutter)');
  } else if (globalSkill) {
    ok('installed globally (~/.claude/skills/river-cli-flutter)');
  } else {
    warn(
        'not installed — run "river_cli skill" to enable AI-assisted workflow');
  }

  // --- Summary ---
  print('\n${'=' * 40}');
  if (problems == 0) {
    print('All checks passed. You are good to go!');
  } else {
    print('$problems item(s) need attention (see ! and ✗ above).');
  }
}
