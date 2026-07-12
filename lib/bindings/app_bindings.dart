import 'package:get/get.dart';

import '../services/llm_service.dart';
import '../services/model_manager.dart';
import '../services/chat_storage_service.dart';
import '../services/local_api_server_service.dart';
import '../services/wakelock_service.dart';
import '../services/log_service.dart';
import '../services/summarizer_service.dart';
import '../services/context_assembler.dart';
import '../controllers/chat_controller.dart';
import '../controllers/model_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/agent_controller.dart';

/// Initial bindings — registers all services and controllers with GetX DI.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // ── Services (async init happens in main.dart) ──────────────────
    Get.lazyPut(() => LlmService(), fenix: true);
    Get.lazyPut(() => ModelManager(), fenix: true);
    Get.lazyPut(() => ChatStorageService(), fenix: true);
    Get.lazyPut(() => LocalApiServerService(), fenix: true);
    Get.lazyPut(() => WakelockService(), fenix: true);
    Get.lazyPut(() => LogService(), fenix: true);

    // ── Agentic AI Services ────────────────────────────────────────
    // Note: MemoryService, VoiceService, ToolService, WorkFolderService,
    // and SandboxService are registered via Get.put() in main.dart
    // with permanent: true because they need early async initialization.
    Get.lazyPut(() => SummarizerService(), fenix: true);
    Get.lazyPut(() => ContextAssembler(), fenix: true);

    // ── Agentic AI Controllers ────────────────────────────────────
    Get.lazyPut(() => AgentController(), fenix: true);

    // ── Controllers ────────────────────────────────────────────────
    Get.put(ThemeController());
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => ModelController(), fenix: true);
  }
}
