import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SandboxResult {
  final bool success;
  final String stdout;
  final String stderr;
  final int exitCode;
  final int durationMs;
  final bool timedOut;

  SandboxResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.durationMs,
    this.timedOut = false,
  });

  bool get hasOutput => stdout.isNotEmpty || stderr.isNotEmpty;
}

class SandboxService extends GetxService {
  // Dangerous imports/patterns to block
  static const List<String> _blocklist = [
    'os.system', 'subprocess', 'socket', 'urllib',
    'requests', 'httplib', 'ftplib', 'smtplib',
    'eval(', 'exec(',
  ];

  String? _workDir;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _workDir = p.join(dir.path, 'sandbox');
    final sandboxDir = Directory(_workDir!);
    if (!await sandboxDir.exists()) {
      await sandboxDir.create(recursive: true);
    }
  }

  Future<SandboxResult> execute(String code) async {
    await init();
    final stopwatch = Stopwatch()..start();

    // Safety check
    for (final blocked in _blocklist) {
      if (code.contains(blocked)) {
        return SandboxResult(
          success: false,
          stdout: '',
          stderr: 'Security error: "$blocked" is not allowed in sandbox',
          exitCode: -1,
          durationMs: 0,
        );
      }
    }

    // Write code to temp file
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final scriptPath = p.join(_workDir!, 'sandbox_$timestamp.py');
    final scriptFile = File(scriptPath);
    await scriptFile.writeAsString(code);

    try {
      // Try Termux Python first
      final result = await _runWithTimeout(
        ['am', 'startservice', '--user', '0',
         '-n', 'com.termux/com.termux.app.RunCommandService',
         '--es', 'com.termux.RUN_COMMAND_PATH', '/data/data/com.termux/files/usr/bin/python3',
         '--esa', 'com.termux.RUN_COMMAND_ARGUMENTS', scriptPath],
        Duration(seconds: 10),
      );

      stopwatch.stop();
      await scriptFile.delete();

      if (result != null) {
        return SandboxResult(
          success: result.exitCode == 0,
          stdout: result.stdout.toString(),
          stderr: result.stderr.toString(),
          exitCode: result.exitCode,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Fallback: check if basic Python is available
      return SandboxResult(
        success: false,
        stdout: '',
        stderr: 'Python runtime not available. Install Termux from F-Droid to enable code execution.',
        exitCode: -1,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      await scriptFile.delete();
      return SandboxResult(
        success: false,
        stdout: '',
        stderr: 'Execution error: $e',
        exitCode: -1,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  Future<ProcessResult?> _runWithTimeout(
    List<String> command,
    Duration timeout,
  ) async {
    try {
      final result = await Process.run(
        command.first,
        command.skip(1).toList(),
        workingDirectory: _workDir,
        stdoutEncoding: const SystemEncoding(),
        stderrEncoding: const SystemEncoding(),
      ).timeout(timeout, onTimeout: () {
        return ProcessResult(-1, -1, '', 'Execution timed out after ${timeout.inSeconds}s');
      });
      return result;
    } catch (e) {
      return null;
    }
  }
}