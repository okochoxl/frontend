import 'dart:io';  // File 때문에 import 했지만, Web 분기 내부에서만 사용
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;  // 추가
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'result_screen.dart';

class PracticeScreen extends StatefulWidget {
  final String category;
  const PracticeScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool isVoiceMode = true; // 음성 인식 모드

  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  String _lastWords = '';

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _videoFile;

  // 동적으로 상황별 문장 설정
  late String _prompt;

  final Map<String, String> promptMap = {
    'Psychiatry': "I’ve been having trouble sleeping.",
    'Medical Treatment': "My stomach really hurts.",
    'Pharmacy': "My throat hurts and I have a cough.",
    'Custom': "Your voice matters,\nno matter how it is heard.",
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Web이면 카메라 초기화 아예 안 함
    if (!kIsWeb) {
      _initCameras();
    }
    _prompt =
        promptMap[widget.category] ??
        "Your voice matters,\nno matter how it is heard.";
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  Future<void> _initCameras() async {
    // 모바일(Android/iOS)인 경우에만 실행
    if (kIsWeb) return;

    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      setState(() {});
    }
  }

// 녹화 시작
Future<void> _startVideoRecording() async {
    if (kIsWeb) return;  // Web에선 스킵
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (!_cameraController!.value.isRecordingVideo) {
      await _cameraController!.startVideoRecording();
    }
  }


void _startListening() async {
  if (!_speechEnabled) return;
  await _speech.listen(
    onResult: (val) {
      setState(() {
        _lastWords = val.recognizedWords;  // 여기에 인식된 문장(텍스트)이 들어옴
      });
    },
  );
}
  void _stopListening() async {
  await _speech.stop();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ResultScreen(
        category: widget.category,
        originalText: _prompt,
        userText: _lastWords,
        isVoiceMode: true,
        aiGuideAsset: 'assets/videos/ai_guide.mp4', // AI 가이드 비디오(없으면 null)
              ),
    ),
  );
}

// 녹화 종료
  void _stopVideoRecording() async {
    if (kIsWeb) {
      // Web일 때는 간단히 결과 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            category: widget.category,
            originalText: _prompt,
            userText: '[Web: video not supported]',
            isVoiceMode: false,
            aiGuideAsset: null,
          ),
        ),
      );
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }
    XFile file = await _cameraController!.stopVideoRecording();
    setState(() => _videoFile = file);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          category: widget.category,
          originalText: _prompt,
          userText: file.path,
          isVoiceMode: false,
          aiGuideAsset: 'assets/videos/ai_guide.mp4',
        ),
      ),
    );
  }
  // 3) 여기에 _startSession() 추가
  /// VOICE 모드면 STT 시작, VIDEO 모드면 녹화 시작 후
  /// 10초 뒤 _stopListening/_stopVideoRecording 을 호출합니다.
  void _startSession() {
    if (isVoiceMode) {
      _startListening();
      Future.delayed(const Duration(seconds: 8), _stopListening);
    } else {
      _startVideoRecording();
      Future.delayed(const Duration(seconds: 8), _stopVideoRecording);
    }
  }

  void _goToResult({
  required String originalText,
  required String userText,
  required bool isVoiceMode,
  String? aiGuideAsset,
}) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ResultScreen(
        category: widget.category,
        originalText: originalText,
        userText: userText,
        isVoiceMode: isVoiceMode,
        aiGuideAsset: aiGuideAsset,
      ),
    ),
  );
}

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
        backgroundColor: const Color(0xFFFAF7FF),
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFFAF7FF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('발음해 보세요!', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Text(
              _prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
           GestureDetector(
   onTap: _startSession,  // ← 여기 한 줄로 대체!
   child: CircleAvatar(
     radius: 48,
     backgroundColor: Colors.grey.shade200,
     child: Icon(
       isVoiceMode ? Icons.mic : Icons.videocam,
       size: 40,
       color: Colors.black54,
     ),
   ),
),
          const SizedBox(height: 28),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          isVoiceMode ? const Color(0xFFE7E0F8) : null,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(30),
                        ),
                      ),
                    ),
                    onPressed: () => setState(() => isVoiceMode = true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isVoiceMode) const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                        const Text('VOICE', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          !isVoiceMode ? const Color(0xFFE7E0F8) : null,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(30),
                        ),
                      ),
                    ),
                    onPressed: () => setState(() => isVoiceMode = false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isVoiceMode) const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                        const Text('VIDEO', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
