import 'dart:async';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/memory_model.dart';

class MemoryService extends GetxService {
  Database? _db;
  final isReady = false.obs;
  final semanticMemories = <SemanticMemory>[].obs;
  final episodicMemories = <EpisodicMemory>[].obs;
  final proceduralMemories = <ProceduralMemory>[].obs;

  Future<String> _getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'agent_memory.db');
  }

  Future<MemoryService> init() async {
    final dbPath = await _getDbPath();
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chat_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            metadata TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE memories (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            importance REAL DEFAULT 0.5,
            timestamp INTEGER NOT NULL,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS memory_fts USING fts5(
            content, importance, tokenize='porter unicode61'
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_memories_type ON memories(type)
        ''');
        await db.execute('''
          CREATE INDEX idx_memories_importance ON memories(importance DESC)
        ''');
      },
    );
    isReady.value = true;
    await _loadMemories();
    return this;
  }

  Future<void> _loadMemories() async {
    if (_db == null) return;
    final rows = await _db!.query('memories', orderBy: 'importance DESC');
    semanticMemories.clear();
    episodicMemories.clear();
    proceduralMemories.clear();
    for (final row in rows) {
      final type = row['type'] as String;
      final content = row['content'] as String;
      final id = row['id'] as String;
      final importance = (row['importance'] as num?)?.toDouble() ?? 0.5;
      final ts = DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
      switch (type) {
        case 'semantic':
          semanticMemories.add(SemanticMemory(
            id: id, timestamp: ts, importance: importance,
            content: content, subject: content, predicate: 'is',
          ));
        case 'episodic':
          episodicMemories.add(EpisodicMemory(
            id: id, timestamp: ts, importance: importance,
            content: content, event: content,
          ));
        case 'procedural':
          proceduralMemories.add(ProceduralMemory(
            id: id, timestamp: ts, importance: importance,
            content: content, taskName: content, steps: [],
          ));
      }
    }
  }

  Future<void> storeConversationTurn(ConversationTurn turn) async {
    if (_db == null) return;
    await _db!.insert('messages', {
      'chat_id': 'default',
      'role': turn.role,
      'content': turn.content,
      'timestamp': turn.timestamp.millisecondsSinceEpoch,
    });
  }

  Future<List<ConversationTurn>> getRecentTurns(int count) async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: count,
    );
    return rows.map((r) => ConversationTurn(
      id: (r['id'] as int).toString(),
      role: r['role'] as String,
      content: r['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
    )).toList().reversed.toList();
  }

  Future<List<Memory>> search(String query, {int limit = 10}) async {
    if (_db == null) return [];
    final rows = await _db!.rawQuery('''
      SELECT m.* FROM memories m
      INNER JOIN memory_fts f ON m.content = f.content
      WHERE f.content MATCH ?
      ORDER BY m.importance DESC
      LIMIT ?
    ''', [query, limit]);
    return rows.map((r) => SemanticMemory(
      id: r['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
      importance: (r['importance'] as num).toDouble(),
      content: r['content'] as String,
      subject: r['content'] as String,
      predicate: 'related',
    )).toList();
  }

  Future<void> extractAndStoreFacts(String conversation) async {
    final patterns = [
      RegExp(r"[Mm]y (\w+(?:\s+\w+)*) is ([^.]+)"),
      RegExp(r"[Ii] (?:like|love|prefer) ([^.]+)"),
      RegExp(r"[Ii] am ([^.]+)"),
      RegExp(r"[Ii] (?:don\'t like|hate) ([^.]+)"),
      RegExp(r"[Ii] (?:want|need) ([^.]+)"),
      RegExp(r"[Ii] live in ([^.]+)"),
      RegExp(r"[Ii] work (?:at|for) ([^.]+)"),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(conversation)) {
        if (match.groupCount >= 1) {
          final fact = match.group(0) ?? '';
          final subject = match.group(1) ?? '';
          final obj = match.groupCount >= 2 ? (match.group(2) ?? '') : '';
          if (fact.length > 10) {
            await _storeFact(fact, subject, obj);
          }
        }
      }
    }
  }

  Future<void> _storeFact(String content, String subject, String object) async {
    if (_db == null) return;
    final id = 'fact_${DateTime.now().millisecondsSinceEpoch}_$subject';
    await _db!.insert('memories', {
      'id': id,
      'type': 'semantic',
      'content': content,
      'importance': 0.7,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    semanticMemories.add(SemanticMemory(
      id: id,
      timestamp: DateTime.now(),
      importance: 0.7,
      content: content,
      subject: subject,
      predicate: 'is',
      object: object,
    ));
  }

  Future<void> updateImportance(String memoryId, double importance) async {
    if (_db == null) return;
    await _db!.update('memories', {'importance': importance},
        where: 'id = ?', whereArgs: [memoryId]);
  }

  Future<void> deleteMemory(String id) async {
    if (_db == null) return;
    await _db!.delete('memories', where: 'id = ?', whereArgs: [id]);
    semanticMemories.removeWhere((m) => m.id == id);
    episodicMemories.removeWhere((m) => m.id == id);
    proceduralMemories.removeWhere((m) => m.id == id);
  }

  Future<void> storeSummary(String summary) async {
    await _storeFact('Conversation summary: $summary', 'summary', summary);
  }

  Future<String?> getLatestSummary() async {
    if (_db == null) return null;
    final rows = await _db!.query('memories',
      where: "content LIKE 'Conversation summary:%'",
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['content'] as String).replaceFirst('Conversation summary: ', '');
  }

  @override
  void onClose() {
    _db?.close();
    super.onClose();
  }
}
