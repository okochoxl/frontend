import 'dart:io';
import 'package:camera/camera.dart';
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


  static const String _prompt =
      'Your voice matters,\nno matter how it is heard.';
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initCameras();
  }

  // 음성 인식 초기화
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  // 카메라 초기화
  Future<void> _initCameras() async {
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

  // 음성 녹음 시작/종료
  void _startListening() => _speech.listen(onResult: (val) {
    setState(() => _lastWords = val.recognizedWords);
  });
  void _stopListening() async {
    await _speech.stop();
    _goToResult(originalText: _prompt, userText: _lastWords);
  }

  // 비디오 녹화 시작
  void _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (!_cameraController!.value.isRecordingVideo) {
      await _cameraController!.startVideoRecording();
    }
  }

  // 비디오 녹화 종료
  void _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;
    XFile file = await _cameraController!.stopVideoRecording();
    setState(() => _videoFile = file);
    // 나중에 재생하거나 서버에 업로드할 파일 경로 file.path
    _goToResult(
      originalText: _prompt,
      userText: '[비디오 녹화 완료]\n파일 경로: ${file.path}',
    );
  }

  // 결과 화면으로 이동
  void _goToResult({required String originalText, required String userText}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          originalText: originalText,
          userText: userText,
          category: widget.category,
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
        title: Text(widget.category),           // ← 카테고리명
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
            child: const Text(
                _prompt,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16,height: 1.4),
              ),
            ),
          // 마이크 / 카메라 버튼
          const SizedBox(height: 24),
            GestureDetector(
  onTapDown: (_) {
    if (isVoiceMode) {
      _startListening();
    } else {
      _startVideoRecording();  // (추후 구현할 비디오 녹화 시작 함수)
    }
  },
  onTapUp: (_) {
    if (isVoiceMode) {
      _stopListening();
    } else {
      _stopVideoRecording();   // (추후 구현할 비디오 녹화 종료 함수)
    }
  },
  child: CircleAvatar(
    radius: 48,
    backgroundColor: Colors.grey.shade200,
    child: Icon(
      // ← 아이콘을 모드에 따라 바꿉니다
      isVoiceMode ? Icons.mic : Icons.videocam,
      size: 40,
      color: Colors.black54,
    ),
  ),
),
          const SizedBox(height: 28),
          // Voice / Video 토글
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
                      backgroundColor: isVoiceMode ? const Color(0xFFE7E0F8) : null,
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
                        const Text(
                          'VOICE',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: !isVoiceMode ? const Color(0xFFE7E0F8) : null,
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
                        const Text(
                          'VIDEO',
                          style: TextStyle(fontSize: 16),
                        ),
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
