import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<Map<String, dynamic>> deviceScan() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;

  int totalRam = 0;
  int availableRam = 0;
  try {
    final memInfo = File('/proc/meminfo').readAsStringSync();
    final totalMatch = RegExp(r'MemTotal:\s+(\d+)').firstMatch(memInfo);
    final availMatch = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(memInfo);
    if (totalMatch != null) totalRam = int.parse(totalMatch.group(1)!) * 1024;
    if (availMatch != null) availableRam = int.parse(availMatch.group(1)!) * 1024;
  } catch (_) {}

  String gpu = 'Unknown';
  try {
    final renderer = File('/proc/gpuinfo').readAsStringSync();
    gpu = renderer.trim();
  } catch (_) {
    try {
      final props = await Process.run('getprop', ['ro.hardware.egl']);
      gpu = props.stdout.toString().trim();
    } catch (_) {}
  }

  // List installed apps
  List<String> apps = [];
  try {
    final result = await Process.run('pm', ['list', 'packages']);
    apps = result.stdout.toString().split('\n')
      .where((l) => l.startsWith('package:'))
      .map((l) => l.replaceFirst('package:', '').trim())
      .where((p) => p.isNotEmpty)
      .toList();
  } catch (_) {}

  return {
    'model': androidInfo.model ?? 'Unknown',
    'brand': androidInfo.brand ?? 'Unknown',
    'androidApiLevel': androidInfo.version.sdkInt,
    'totalRam': totalRam,
    'availableRam': availableRam,
    'cpuCores': Platform.numberOfProcessors,
    'gpu': gpu.isNotEmpty ? gpu : 'Adreno 750 (estimated)',
    'screenWidth': 0,
    'screenHeight': 0,
    'screenDpi': 0,
    'installedApps': apps.length,
    'appList': apps.take(50).toList(),
  };
}

Future<String> openApp(String packageName) async {
  try {
    final intent = AndroidIntent(
      action: 'action_main',
      package: packageName,
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
    return 'Opened $packageName';
  } catch (e) {
    return 'Failed to open $packageName: $e';
  }
}

Future<String> readScreen() async {
  return 'Screen reading requires AccessibilityService to be enabled. Go to Settings > Accessibility > Agentic AI > Enable.';
}

Future<String> takeScreenshot() async {
  return 'Screenshot requires AccessibilityService. Use device screenshot button instead.';
}