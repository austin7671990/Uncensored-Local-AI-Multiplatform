import 'package:flutter/material.dart';
import '../services/sandbox_service.dart';

class SandboxOutput extends StatelessWidget {
  final SandboxResult? result;
  final bool isRunning;

  const SandboxOutput({
    super.key,
    this.result,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1a1a2e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Icon(Icons.terminal, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  'Sandbox Output',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (result != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: result!.success
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result!.success ? 'PASS' : 'FAIL',
                      style: TextStyle(
                        color: result!.success ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (result != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${result!.durationMs}ms',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Output area
          Expanded(
            child: isRunning
                ? const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Running in sandbox...',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : result == null
                    ? const Center(
                        child: Text(
                          'Run code to see output',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (result!.stdout.isNotEmpty)
                              SelectableText(
                                result!.stdout,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  height: 1.4,
                                ),
                              ),
                            if (result!.stderr.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SelectableText(
                                result!.stderr,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (!result!.success && result!.stderr.isEmpty)
                              SelectableText(
                                'Exit code: ${result!.exitCode}',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
