import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> _getWorkDir() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'work');
}

Future<String> readFile(String path) async {
  final workDir = await _getWorkDir();
  final filePath = p.join(workDir!, path);
  final file = File(filePath);
  if (!await file.exists()) return 'File not found: $path';
  return await file.readAsString();
}

Future<String> writeFile(String name, String content) async {
  final workDir = await _getWorkDir();
  final dir = Directory(workDir!);
  if (!await dir.exists()) await dir.create(recursive: true);

  // Security: only allow writing to work directory
  final cleanName = p.basename(name);
  final filePath = p.join(workDir, cleanName);
  final file = File(filePath);
  await file.writeAsString(content);
  return 'File written: $cleanName (${content.length} chars)';
}

Future<List<String>> listFiles(String? path) async {
  final workDir = await _getWorkDir();
  final targetDir = path != null && path.isNotEmpty
      ? Directory(p.join(workDir!, path))
      : Directory(workDir!);

  if (!await targetDir.exists()) return [];

  final files = <String>[];
  await for (final entity in targetDir.list()) {
    final name = p.basename(entity.path);
    if (entity is Directory) {
      files.add('📁 $name/');
    } else {
      final size = await entity.stat().then((s) => s.size);
      files.add('📄 $name (${_formatSize(size)})');
    }
  }
  return files;
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}