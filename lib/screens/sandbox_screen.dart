import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/sandbox_service.dart';

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final SandboxService _sandbox = Get.find<SandboxService>();
  final TextEditingController _codeController = TextEditingController();
  SandboxResult? _result;
  bool _isRunning = false;

  Future<void> _runCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isRunning = true;
      _result = null;
    });

    final result = await _sandbox.execute(code);

    setState(() {
      _result = result;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sandbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _isRunning ? null : _runCode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Code input
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF282c34),
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: '# Enter Python code here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Divider
          const Divider(height: 1, color: Colors.grey),

          // Output
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF1a1a2e),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: _isRunning
                  ? const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Running...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : _result == null
                      ? const Center(
                          child: Text('Output will appear here', style: TextStyle(color: Colors.grey)),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_result!.stdout.isNotEmpty)
                                SelectableText(
                                  _result!.stdout,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              if (_result!.stderr.isNotEmpty)
                                SelectableText(
                                  _result!.stderr,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              if (!_result!.success && _result!.stderr.isEmpty)
                                Text(
                                  'Exit code: ${_result!.exitCode}',
                                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                '${_result!.durationMs}ms',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}