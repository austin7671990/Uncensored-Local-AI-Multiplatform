import 'dart:async';
import 'package:flutter/services.dart';

const _accessibilityChannel = MethodChannel(
  'com.portableai.portable_ai_flutter/accessibility',
);

Future<String> tapScreen(int x, int y) async {
  try {
    final result = await _accessibilityChannel.invokeMethod<String>('tap', {
      'x': x,
      'y': y,
    });
    return result ?? 'Tap completed.';
  } on PlatformException catch (e) {
    return 'Tap failed: ${e.message}. Ensure Accessibility Service is enabled in Settings > Accessibility > Agentic AI.';
  } catch (e) {
    return 'Tap error: $e';
  }
}

Future<String> swipeScreen(int x1, int y1, int x2, int y2) async {
  try {
    final result = await _accessibilityChannel.invokeMethod<String>('swipe', {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
    });
    return result ?? 'Swipe completed.';
  } on PlatformException catch (e) {
    return 'Swipe failed: ${e.message}. Ensure Accessibility Service is enabled.';
  } catch (e) {
    return 'Swipe error: $e';
  }
}

Future<String> typeText(String text) async {
  try {
    final result = await _accessibilityChannel.invokeMethod<String>('typeText', {
      'text': text,
    });
    return result ?? 'Text input completed.';
  } on PlatformException catch (e) {
    return 'Type failed: ${e.message}. Ensure Accessibility Service is enabled and a text field is focused.';
  } catch (e) {
    return 'Type error: $e';
  }
}

Future<String> pressKey(String key) async {
  final validKeys = ['back', 'home', 'recents', 'power', 'volume_up', 'volume_down', 'notifications', 'quick_settings'];
  if (!validKeys.contains(key.toLowerCase())) {
    return 'Unknown key: $key. Valid keys: ${validKeys.join(', ')}';
  }

  try {
    final result = await _accessibilityChannel.invokeMethod<String>('pressKey', {
      'key': key.toLowerCase(),
    });
    return result ?? 'Key press completed.';
  } on PlatformException catch (e) {
    return 'Key press failed: ${e.message}. Ensure Accessibility Service is enabled.';
  } catch (e) {
    return 'Key press error: $e';
  }
}
