import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

final _dangerousCommands = [
  'rm -rf /', 'mkfs', 'dd if=', 'format',
  'chmod 777 /', 'chown root',
  '> /dev/sda', 'mv / ', ':(){ :|:& };:',
];

Future<String> runShellCommand(String command) async {
  // Safety check
  for (final dangerous in _dangerousCommands) {
    if (command.contains(dangerous)) {
      return 'Blocked: "$dangerous" is a dangerous command and has been blocked for safety.';
    }
  }

  try {
    // Try Termux RUN_COMMAND
    final intent = AndroidIntent(
      action: 'com.termux.RUN_COMMAND',
      package: 'com.termux',
      componentName: 'com.termux.app.RunCommandService',
      arguments: <String, dynamic>{
        'com.termux.RUN_COMMAND_PATH': '/data/data/com.termux/files/usr/bin/bash',
        'com.termux.RUN_COMMAND_ARGUMENTS': <String>['-c', command],
      },
    );
    await intent.launch();
    return 'Command sent to Termux: $command';
  } catch (e) {
    // Fallback: try direct process execution
    try {
      final result = await Process.run('sh', ['-c', command], runInShell: true);
      final output = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      if (err.isNotEmpty) {
        return 'Exit ${result.exitCode}\n$output\nSTDERR: $err';
      }
      return output.isEmpty ? '(no output)' : output;
    } catch (procError) {
      return 'Shell execution failed. Install Termux from F-Droid for full shell access. Error: $procError';
    }
  }
}