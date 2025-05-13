// lib/screens/result_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ResultScreen extends StatefulWidget {
  final String category;
  final String originalText;
  final String userText;      // VOICE 모드: 텍스트 / VIDEO 모드: 파일 경로
  final bool isVoiceMode;     // true: 음성 모드, false: 영상 모드
  final String? aiGuideAsset; // AI 가이드용 비디오(asset 경로)

  const ResultScreen({
    Key? key,
    required this.category,
    required this.originalText,
    required this.userText,
    required this.isVoiceMode,
    this.aiGuideAsset,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VideoPlayerController? _userVideoCtr;
  VideoPlayerController? _aiVideoCtr;

  // ① AI 솔루션 문자열을 저장할 상태 변수
  String? _aiSolution;
  bool   _loadingAI = false;

  @override
  void initState() {
    super.initState();


    if (!widget.isVoiceMode) {
      // 사용자가 녹화한 비디오 로드
      _userVideoCtr = VideoPlayerController.file(File(widget.userText))
        ..initialize().then((_) => setState(() {}));
      // AI 가이드 비디오 로드 (asset)
      if (widget.aiGuideAsset != null) {
        _aiVideoCtr = VideoPlayerController.asset(widget.aiGuideAsset!)
          ..initialize().then((_) => setState(() {}));
      }
    }

    // ② VOICE 모드일 때 AI 솔루션을 호출
    if (widget.isVoiceMode) {
      _fetchAISolution();
    }
  }

  @override
  void dispose() {
    _userVideoCtr?.dispose();
    _aiVideoCtr?.dispose();
    super.dispose();
  }

  // ③ Gemini 호출 부분 (플레이스홀더)
  Future<String> fetchPronunciationAdvice(String original, String user) async {
    // TODO: 여기에 Gemini API 클라이언트를 이용한 실제 호출 코드 작성
    //
    // 예시(의사코드)👇
    // final client = GeminiClient(apiKey: 'YOUR_API_KEY');
    // final resp = await client.chat(
    //   system: '당신은 발음 교정 전문 AI입니다.',
    //   user: '''
    //     Original: "$original"
    //     UserPronunciation: "$user"
    //     Please give me step-by-step advice on how to improve the user's pronunciation.
    //   '''
    // );
    // return resp.choices.first.text;
    //
    // 지금은 더미 리턴
    await Future.delayed(const Duration(milliseconds: 500));
    return '“Su” → “So”: Try making your mouth shape a bit smaller.\n'
           '“Seo” → “Sa”: Open your mouth wider and roll your tongue slightly.';
  }


  Future<void> _fetchAISolution() async {
    setState(() => _loadingAI = true);
    final advice = await fetchPronunciationAdvice(
      widget.originalText,
      widget.userText,
    );
    setState(() {
      _aiSolution = advice;
      _loadingAI  = false;
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Text(
              'Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    AssetImage('assets/images/avatar_placeholder.png'),
              ),
            ),
            const SizedBox(height: 16),

            // correct pronun
            Row(
              children: [
                _tag('correct pronun'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.originalText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // your pronun
            Row(
              children: [
                _tag('your pronun'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isVoiceMode
                        ? (widget.userText.isEmpty ? '-' : widget.userText)
                        : '[See your video below]',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'AI Solution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            
            // ④ 로딩 중이면 스피너, 완료되면 박스에 텍스트
            if (_loadingAI)
              Center(child: CircularProgressIndicator())
            else if (_aiSolution != null)
              _boxedText(_aiSolution!)
            else
              _boxedText('No advice available.'),

            const SizedBox(height: 24),
            // VOICE vs VIDEO 분기
            if (widget.isVoiceMode) ...[
              const Text(
                'AI Pronunciation Guide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPlaceholder(),
            ] else ...[
              const Text(
                'Your Pronunciation Video',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVideoPlayer(_userVideoCtr),
              const SizedBox(height: 24),
              const Text(
                'AI Pronunciation Guide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVideoPlayer(_aiVideoCtr),
            ],

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3FD3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      );

  Widget _boxedText(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(t, style: const TextStyle(fontSize: 14)),
      );

  Widget _buildPlaceholder() => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFE7E0F8)),
          ),
        ),
      );

  Widget _buildVideoPlayer(VideoPlayerController? ctr) {
    if (ctr == null || !ctr.value.isInitialized) return _buildPlaceholder();
    return AspectRatio(
      aspectRatio: ctr.value.aspectRatio,
      child: VideoPlayer(ctr),
    );
  }
}
