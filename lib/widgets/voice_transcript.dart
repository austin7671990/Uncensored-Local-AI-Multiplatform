import 'package:flutter/material.dart';

class TranscriptEntry {
  final String speaker;
  final String text;
  final DateTime timestamp;

  TranscriptEntry({
    required this.speaker,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class VoiceTranscript extends StatelessWidget {
  final List<TranscriptEntry> entries;
  final ScrollController? scrollController;

  const VoiceTranscript({
    super.key,
    required this.entries,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Your conversation will appear here',
          style: TextStyle(color: Colors.white30, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isUser = entry.speaker == 'You';

        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.blueAccent.withOpacity(0.2)
                    : Colors.grey.shade800.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser
                      ? Colors.blueAccent.withOpacity(0.3)
                      : Colors.grey.shade700.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.speaker,
                    style: TextStyle(
                      color: isUser ? Colors.blueAccent : Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}