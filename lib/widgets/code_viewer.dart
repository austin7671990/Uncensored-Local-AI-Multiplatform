import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

class CodeViewer extends StatelessWidget {
  final String code;
  final String filename;

  const CodeViewer({
    super.key,
    required this.code,
    required this.filename,
  });

  String get _language {
    if (filename.endsWith('.py')) return 'python';
    if (filename.endsWith('.dart')) return 'dart';
    if (filename.endsWith('.js')) return 'javascript';
    if (filename.endsWith('.json')) return 'json';
    if (filename.endsWith('.yaml') || filename.endsWith('.yml')) return 'yaml';
    if (filename.endsWith('.sh')) return 'bash';
    if (filename.endsWith('.md')) return 'markdown';
    if (filename.endsWith('.xml')) return 'xml';
    if (filename.endsWith('.html')) return 'html';
    if (filename.endsWith('.css')) return 'css';
    if (filename.endsWith('.sql')) return 'sql';
    if (filename.endsWith('.c') || filename.endsWith('.h')) return 'c';
    if (filename.endsWith('.cpp') || filename.endsWith('.hpp')) return 'cpp';
    if (filename.endsWith('.java')) return 'java';
    if (filename.endsWith('.kt')) return 'kotlin';
    if (filename.endsWith('.rs')) return 'rust';
    if (filename.endsWith('.go')) return 'go';
    if (filename.endsWith('.rb')) return 'ruby';
    return 'plaintext';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF282c34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filename header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Icon(Icons.code, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  filename,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${code.split('\n').length} lines',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Code with syntax highlighting
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: HighlightView(
                  code,
                  language: _language,
                  theme: atomOneDarkTheme,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}