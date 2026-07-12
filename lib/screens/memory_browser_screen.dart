import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/memory_service.dart';
import '../models/memory_model.dart';

class MemoryBrowserScreen extends StatelessWidget {
  const MemoryBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memoryService = Get.find<MemoryService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Browser')),
      body: Obx(() {
        if (!memoryService.isReady.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('Semantic Memories (${memoryService.semanticMemories.length})'),
            ...memoryService.semanticMemories.map((m) => _MemoryCard(m)),
            _SectionHeader('Episodic Memories (${memoryService.episodicMemories.length})'),
            ...memoryService.episodicMemories.map((m) => _MemoryCard(m)),
            _SectionHeader('Procedural Memories (${memoryService.proceduralMemories.length})'),
            ...memoryService.proceduralMemories.map((m) => _MemoryCard(m)),
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  const _MemoryCard(this.memory);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(memory.content, maxLines: 3, overflow: TextOverflow.ellipsis),
        subtitle: Text('Importance: ${(memory.importance * 100).toStringAsFixed(0)}%'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => Get.find<MemoryService>().deleteMemory(memory.id),
        ),
      ),
    );
  }
}