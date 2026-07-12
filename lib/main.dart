import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models/chat_model.dart';
import 'models/message_model.dart';
import 'theme/app_theme.dart';
import 'bindings/app_bindings.dart';
import 'controllers/theme_controller.dart';
import 'screens/splash_screen.dart';
import 'routes/app_routes.dart';
import 'services/memory_service.dart';
import 'services/voice_service.dart';
import 'services/tool_service.dart';
import 'services/work_folder_service.dart';
import 'services/sandbox_service.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformError: $error\n$stack');
      return true;
    };

    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);

    Hive.registerAdapter(ChatModelAdapter());
    Hive.registerAdapter(MessageModelAdapter());
    Hive.registerAdapter(MessageRoleAdapter());

    await Hive.openBox<ChatModel>('chats');
    await Hive.openBox('settings');
    await Hive.openBox('models_meta');

    final themeController = Get.put(ThemeController());

    // Initialize agentic AI services
    try {
      final memoryService = Get.put(MemoryService(), permanent: true);
      await memoryService.init();
    } catch (e) { debugPrint('MemoryService init: $e'); }

    try {
      final voiceService = Get.put(VoiceService(), permanent: true);
      await voiceService.init();
    } catch (e) { debugPrint('VoiceService init: $e'); }

    try {
      Get.put(ToolService(), permanent: true);
    } catch (e) { debugPrint('ToolService init: $e'); }

    try {
      final workFolderService = Get.put(WorkFolderService(), permanent: true);
      await workFolderService.init();
    } catch (e) { debugPrint('WorkFolderService init: $e'); }

    try {
      Get.put(SandboxService(), permanent: true);
    } catch (e) { debugPrint('SandboxService init: $e'); }

    runApp(PortableAIApp(themeController: themeController));
  }, (error, stack) {
    debugPrint('Unhandled: $error\n$stack');
  });
}

class PortableAIApp extends StatelessWidget {
  final ThemeController themeController;

  const PortableAIApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Agentic AI',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}