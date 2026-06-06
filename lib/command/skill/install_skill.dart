import 'dart:io';

import '../../static/skills/river_skill.dart';

/// Handles `river_cli skill` — installs the bundled Claude Code skill into a
/// project's (or the user's) `.claude/skills/` directory so AI assistants pick
/// up the river_cli workflow automatically.
void runSkill(List<String> args) {
  final help = args.contains('--help') || args.contains('-h');
  final global = args.contains('--global') || args.contains('-g');
  final force = args.contains('--force') || args.contains('-f');
  final printOnly = args.contains('--print') || args.contains('-p');

  if (help) {
    _printHelp();
    return;
  }

  if (printOnly) {
    stdout.write(kRiverSkillContent.startsWith('\n')
        ? kRiverSkillContent.substring(1)
        : kRiverSkillContent);
    return;
  }

  final base = global ? _globalClaudeDir() : '.claude';
  if (base == null) {
    print('Error: could not resolve the home directory for --global install.');
    exit(1);
  }

  final skillDir = '$base/skills/river-cli-flutter';
  final target = File('$skillDir/$kSkillFileName');

  final existed = target.existsSync();
  if (existed && !force) {
    print('Skill already installed at ${target.path}.');
    print('Use "river_cli skill --force" to overwrite it.');
    return;
  }

  Directory(skillDir).createSync(recursive: true);
  final content = kRiverSkillContent.startsWith('\n')
      ? kRiverSkillContent.substring(1)
      : kRiverSkillContent;
  target.writeAsStringSync(content);

  print('${existed ? 'Updated' : 'Installed'} Claude Code skill:');
  print('  ${target.path}');
  print('\nThe "river-cli-flutter" skill is now available to Claude Code'
      '${global ? ' across all your projects.' : ' in this project.'}');
}

String? _globalClaudeDir() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null || home.isEmpty) return null;
  return '$home/.claude';
}

void _printHelp() {
  print('''
Usage: river_cli skill [options]

Installs the bundled "river-cli-flutter" Claude Code skill so AI coding
assistants follow the river_cli workflow (scaffold with the CLI, compose with
the widget library, style with design tokens).

By default it writes to ./.claude/skills/river-cli-flutter/SKILL.md.

Options:
  -g, --global   Install to ~/.claude/skills (available in every project)
  -f, --force    Overwrite an existing skill file
  -p, --print    Print the skill to stdout instead of writing a file
  -h, --help     Show this help and exit

Examples:
  river_cli skill                 # install into the current project
  river_cli skill --global        # install for all projects
  river_cli skill --print > SKILL.md''');
}
