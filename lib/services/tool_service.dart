import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';

import '../models/tool_model.dart';
import 'tools/device_tools.dart';
import 'tools/input_tools.dart';
import 'tools/shell_tools.dart';
import 'tools/file_tools.dart';
import 'tools/web_tools.dart';

class ToolService extends GetxService {
  final List<ToolDefinition> _tools = [];
  final RxBool toolsEnabled = true.obs;
  final RxList<Map<String, dynamic>> executionLog = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    registerAllTools();
  }

  void registerAllTools() {
    _tools.clear();

    // Device tools
    _tools.add(ToolDefinition(
      name: 'device_scan',
      description: 'Scan device for hardware info and installed apps',
      parametersSchema: {},
      category: ToolCategory.device,
      handler: (args) => deviceScan(),
    ));
    _tools.add(ToolDefinition(
      name: 'open_app',
      description: 'Open an installed app by package name',
      parametersSchema: {'package': 'string - Android package name'},
      category: ToolCategory.device,
      handler: (args) => openApp(args['package'] ?? ''),
    ));
    _tools.add(ToolDefinition(
      name: 'read_screen',
      description: 'Read all visible UI elements on screen',
      parametersSchema: {},
      category: ToolCategory.device,
      handler: (args) => readScreen(),
    ));
    _tools.add(ToolDefinition(
      name: 'take_screenshot',
      description: 'Capture the current screen',
      parametersSchema: {},
      category: ToolCategory.device,
      handler: (args) => takeScreenshot(),
    ));

    // Input tools
    _tools.add(ToolDefinition(
      name: 'tap_screen',
      description: 'Tap at x,y coordinates',
      parametersSchema: {'x': 'int', 'y': 'int'},
      category: ToolCategory.input,
      requiresConfirmation: true,
      handler: (args) => tapScreen(args['x'] ?? 0, args['y'] ?? 0),
    ));
    _tools.add(ToolDefinition(
      name: 'swipe_screen',
      description: 'Swipe from x1,y1 to x2,y2',
      parametersSchema: {'x1': 'int', 'y1': 'int', 'x2': 'int', 'y2': 'int'},
      category: ToolCategory.input,
      requiresConfirmation: true,
      handler: (args) => swipeScreen(
        args['x1'] ?? 0, args['y1'] ?? 0,
        args['x2'] ?? 0, args['y2'] ?? 0,
      ),
    ));
    _tools.add(ToolDefinition(
      name: 'type_text',
      description: 'Type text into the focused input field',
      parametersSchema: {'text': 'string'},
      category: ToolCategory.input,
      requiresConfirmation: true,
      handler: (args) => typeText(args['text'] ?? ''),
    ));
    _tools.add(ToolDefinition(
      name: 'press_key',
      description: 'Press a system key: back, home, recents, power, volume_up, volume_down',
      parametersSchema: {'key': 'string'},
      category: ToolCategory.input,
      requiresConfirmation: true,
      handler: (args) => pressKey(args['key'] ?? ''),
    ));

    // Shell tools
    _tools.add(ToolDefinition(
      name: 'run_shell',
      description: 'Execute a shell command via Termux',
      parametersSchema: {'command': 'string'},
      category: ToolCategory.shell,
      requiresConfirmation: true,
      handler: (args) => runShellCommand(args['command'] ?? ''),
    ));

    // File tools
    _tools.add(ToolDefinition(
      name: 'read_file',
      description: 'Read a file from device storage',
      parametersSchema: {'path': 'string'},
      category: ToolCategory.file,
      handler: (args) => readFile(args['path'] ?? ''),
    ));
    _tools.add(ToolDefinition(
      name: 'write_file',
      description: 'Write content to the work folder',
      parametersSchema: {'path': 'string', 'content': 'string'},
      category: ToolCategory.file,
      requiresConfirmation: true,
      handler: (args) => writeFile(args['path'] ?? '', args['content'] ?? ''),
    ));
    _tools.add(ToolDefinition(
      name: 'list_files',
      description: 'List files in a directory',
      parametersSchema: {'path': 'string'},
      category: ToolCategory.file,
      handler: (args) => listFiles(args['path'] ?? ''),
    ));

    // Web tools
    _tools.add(ToolDefinition(
      name: 'web_search',
      description: 'Search the web via DuckDuckGo',
      parametersSchema: {'query': 'string'},
      category: ToolCategory.web,
      handler: (args) => webSearch(args['query'] ?? ''),
    ));

    // Sandbox
    _tools.add(ToolDefinition(
      name: 'sandbox_code',
      description: 'Run Python code in a safe sandbox',
      parametersSchema: {'code': 'string'},
      category: ToolCategory.sandbox,
      handler: (args) => runSandboxCode(args['code'] ?? ''),
    ));
  }

  String getToolSystemPrompt() {
    if (!toolsEnabled.value) return '';
    return ToolSystemPromptBuilder.buildPrompt(_tools);
  }

  ToolCall? parseToolCall(String modelOutput) {
    try {
      final cleaned = modelOutput.trim();
      String jsonStr = cleaned;

      // Try to find JSON in markdown code fences
      final fenceMatch = RegExp(r'```json\s*(.*?)\s*```', dotAll: true).firstMatch(cleaned);
      if (fenceMatch != null) jsonStr = fenceMatch.group(1)!;

      final json = jsonDecode(jsonStr);
      if (json is Map && (json['tool'] != null || json['name'] != null)) {
        return ToolCall.fromJson(Map<String, dynamic>.from(json));
      }
    } catch (_) {}
    return null;
  }

  Future<ToolResult> executeTool(ToolCall call) async {
    final tool = _tools.firstWhereOrNull((t) => t.name == call.toolName);
    if (tool == null) {
      return ToolResult(callId: call.callId, success: false,
          error: 'Tool not found: ${call.toolName}', durationMs: 0);
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await tool.handler(call.parameters);
      stopwatch.stop();
      final toolResult = ToolResult(
        callId: call.callId,
        success: true,
        data: result,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      executionLog.add({
        'tool': call.toolName,
        'params': call.parameters,
        'result': toolResult.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      return toolResult;
    } catch (e) {
      stopwatch.stop();
      final toolResult = ToolResult(
        callId: call.callId,
        success: false,
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
      executionLog.add({
        'tool': call.toolName,
        'params': call.parameters,
        'result': toolResult.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      return toolResult;
    }
  }

  bool requiresConfirmation(String toolName) {
    final tool = _tools.firstWhereOrNull((t) => t.name == toolName);
    return tool?.requiresConfirmation ?? false;
  }

  void toggleTools() {
    toolsEnabled.value = !toolsEnabled.value;
  }

  List<ToolDefinition> get allTools => List.unmodifiable(_tools);
}