import 'package:flutter/material.dart';
import '../services/work_folder_service.dart';

class FileTree extends StatelessWidget {
  final List<WorkFile> files;
  final Function(WorkFile) onFileTap;
  final WorkFile? selectedFile;

  const FileTree({
    super.key,
    required this.files,
    required this.onFileTap,
    this.selectedFile,
  });

  IconData _getFileIcon(String name, bool isDirectory) {
    if (isDirectory) return Icons.folder;
    if (name.endsWith('.py')) return Icons.code;
    if (name.endsWith('.dart')) return Icons.flutter_dash;
    if (name.endsWith('.json')) return Icons.data_object;
    if (name.endsWith('.txt') || name.endsWith('.md')) return Icons.description;
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return Icons.settings;
    if (name.endsWith('.sh')) return Icons.terminal;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String name, bool isDirectory) {
    if (isDirectory) return Colors.amber;
    if (name.endsWith('.py')) return Colors.blue;
    if (name.endsWith('.dart')) return Colors.cyan;
    if (name.endsWith('.json')) return Colors.orange;
    if (name.endsWith('.sh')) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Text('No files yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = selectedFile?.path == file.path;
        final depth = file.path.split('/').length - 1;

        return InkWell(
          onTap: () => onFileTap(file),
          child: Container(
            padding: EdgeInsets.only(
              left: 12.0 + (depth * 16.0),
              right: 12,
              top: 6,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.15) : null,
              border: Border(
                left: isSelected
                    ? const BorderSide(color: Colors.blueAccent, width: 3)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getFileIcon(file.name, file.isDirectory),
                  size: 18,
                  color: _getFileColor(file.name, file.isDirectory),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!file.isDirectory)
                  Text(
                    _formatSize(file.size),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}K';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
  }
}