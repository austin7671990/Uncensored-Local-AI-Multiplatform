import 'package:get/get.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/model_library_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/api_endpoints_screen.dart';
import '../screens/logs_screen.dart';
import '../screens/voice_mode_screen.dart';
import '../screens/work_folder_screen.dart';
import '../screens/sandbox_screen.dart';
import '../screens/memory_browser_screen.dart';
import '../screens/device_info_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const modelLibrary = '/models';
  static const settings = '/settings';
  static const apiEndpoints = '/api-endpoints';
  static const logs = '/logs';

  // Agentic AI Routes
  static const voiceMode = '/voice_mode';
  static const workFolder = '/work_folder';
  static const memoryBrowser = '/memory_browser';
  static const deviceInfo = '/device_info';
  static const sandbox = '/sandbox';

  static final pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(
      name: modelLibrary,
      page: () => const ModelLibraryScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: apiEndpoints,
      page: () => const ApiEndpointsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: logs,
      page: () => const LogsScreen(),
      transition: Transition.rightToLeft,
    ),

    // Agentic AI Screens
    GetPage(
      name: voiceMode,
      page: () => const VoiceModeScreen(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: workFolder,
      page: () => const WorkFolderScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: sandbox,
      page: () => const SandboxScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: memoryBrowser,
      page: () => const MemoryBrowserScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: deviceInfo,
      page: () => const DeviceInfoScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}