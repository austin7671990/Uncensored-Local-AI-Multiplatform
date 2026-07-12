import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/voice_service.dart';
import '../controllers/agent_controller.dart';
import '../widgets/voice_orb.dart';
import '../widgets/voice_transcript.dart';

class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen> {
  final VoiceService _voice = Get.find<VoiceService>();
  final AgentController _agent = Get.find<AgentController>();
  final List<TranscriptEntry> _entries = [];
  final ScrollController _scrollController = ScrollController();
  bool _isInConversation = false;

  @override
  void initState() {
    super.initState();
    _voice.setOnTranscriptComplete(_onTranscriptComplete);
    _startListening();
  }

  Future<void> _startListening() async {
    await _voice.startListening();
    setState(() {});
  }

  void _onTranscriptComplete(String text) async {
    if (text.trim().isEmpty) return;

    // Check for exit command
    if (text.toLowerCase().contains('exit voice mode')) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _entries.add(TranscriptEntry(speaker: 'You', text: text));
      _isInConversation = true;
    });
    _scrollToBottom();

    // Process through agent
    _voice.state.value = VoiceState.thinking;

    final response = await _agent.processMessage(text);

    setState(() {
      _entries.add(TranscriptEntry(speaker: 'Assistant', text: response));
    });
    _scrollToBottom();

    // Speak response
    await _voice.speak(response);

    // Auto-restart listening after TTS
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _voice.startListening();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _voice.stopListening();
    _voice.stopSpeaking();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Voice Mode',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Orb
            Expanded(
              flex: 2,
              child: Center(
                child: Obx(() => VoiceOrb(
                  state: _voice.state.value,
                  audioLevel: _voice.audioLevel.value,
                  size: MediaQuery.of(context).size.width * 0.35,
                )),
              ),
            ),

            // Status text
            Obx(() => Text(
              _statusText(_voice.state.value),
              style: TextStyle(
                color: _statusColor(_voice.state.value),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            )),

            const SizedBox(height: 16),

            // Transcript
            Expanded(
              flex: 3,
              child: VoiceTranscript(
                entries: _entries,
                scrollController: _scrollController,
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mute / Interrupt
                  Obx(() => _voice.isSpeaking.value
                      ? ElevatedButton.icon(
                          onPressed: () {
                            _voice.stopSpeaking();
                            _voice.startListening();
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('Interrupt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(VoiceState state) {
    switch (state) {
      case VoiceState.listening: return 'Listening...';
      case VoiceState.thinking: return 'Thinking...';
      case VoiceState.speaking: return 'Speaking...';
      case VoiceState.error: return 'Error - tap to retry';
      default: return 'Tap orb to speak';
    }
  }

  Color _statusColor(VoiceState state) {
    switch (state) {
      case VoiceState.listening: return Colors.greenAccent;
      case VoiceState.thinking: return Colors.amber;
      case VoiceState.speaking: return Colors.blueAccent;
      case VoiceState.error: return Colors.redAccent;
      default: return Colors.white54;
    }
  }
}