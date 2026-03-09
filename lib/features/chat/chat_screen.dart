import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/ai/chat_service.dart';
import '../../core/models/student.dart';
import '../../core/theme/kawabel_theme.dart';

enum ChatMode { homework, subject }

class ChatScreen extends StatefulWidget {
  final ChatMode mode;
  final String? subject;

  const ChatScreen({
    super.key,
    required this.mode,
    this.subject,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _hasGreeted = false;
  bool _showScrollToBottom = false;

  // Voice input state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the mic icon when listening
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
    _initSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatService>();
      chat.clearMessages();
      if (widget.subject != null) {
        chat.setSubject(widget.subject!);
      }
      _sendGreeting();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final distanceFromBottom = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    final shouldShow = distanceFromBottom > 200;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  /// Initialize speech recognition; silently disable if unavailable (e.g. web).
  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (mounted) setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (e) {
      // speech_to_text throws on platforms that don't support it (web, etc.)
      debugPrint('Speech-to-text not available: $e');
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  /// Pick the recognition locale based on the current subject.
  String _speechLocale() {
    final subj = (widget.subject ?? '').toLowerCase();
    if (subj.contains('mandarin') || subj.contains('chinese')) {
      return 'zh-CN';
    }
    if (subj.contains('english')) {
      return 'en-US';
    }
    // Default: Bahasa Indonesia
    return 'id-ID';
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      _showSpeechUnavailableSnackbar();
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
    } else {
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);

      await _speech.listen(
        localeId: _speechLocale(),
        listenMode: stt.ListenMode.dictation,
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
      );
    }
  }

  void _showSpeechUnavailableSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Suara tidak tersedia di perangkat ini. '
          'Coba di HP ya!',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendGreeting() async {
    if (_hasGreeted) return;
    _hasGreeted = true;

    final student = context.read<StudentProvider>();
    final chat = context.read<ChatService>();

    String greeting;
    if (widget.mode == ChatMode.homework) {
      greeting = 'Halo Kawi! Aku mau minta bantuan untuk PR-ku.';
    } else {
      greeting = 'Halo Kawi! Aku mau belajar ${widget.subject}.';
    }

    await chat.sendMessage(
      text: greeting,
      studentName: student.student!.name,
      grade: student.student!.grade,
      studentId: student.student!.id,
    );
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: KColors.green),
                title: const Text('Ambil Foto'),
                subtitle: const Text('Foto soal atau buku'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: KColors.blue),
                title: const Text('Pilih dari Galeri'),
                subtitle: const Text('Pilih foto yang sudah ada'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    _sendWithImage(bytes, picked.name);
  }

  Future<void> _sendWithImage(Uint8List bytes, String name) async {
    final student = context.read<StudentProvider>();
    final chat = context.read<ChatService>();

    await chat.sendMessage(
      text: 'Tolong bantu aku dengan soal di foto ini.',
      studentName: student.student!.name,
      grade: student.student!.grade,
      studentId: student.student!.id,
      imageBytes: bytes,
      imageName: name,
    );
    _scrollToBottom();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Stop listening if we were recording
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
    }

    _textController.clear();
    final student = context.read<StudentProvider>();
    final chat = context.read<ChatService>();

    await chat.sendMessage(
      text: text,
      studentName: student.student!.name,
      grade: student.student!.grade,
      studentId: student.student!.id,
    );
    _scrollToBottom();
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

  String _inputHint() {
    if (widget.subject != null) {
      return 'Tanya Kawi tentang ${widget.subject}...';
    }
    return 'Tanya Kawi...';
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatService>();
    final isWide = Responsive.isTabletOrLarger(context);
    final studentProvider = context.watch<StudentProvider>();
    final studentInitial = (studentProvider.student?.name.isNotEmpty == true)
        ? studentProvider.student!.name[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: KColors.surface,
      appBar: AppBar(
        backgroundColor: KColors.green,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('\u{1F989} ', style: TextStyle(fontSize: 24)),
            Text(
              widget.subject != null ? 'Kawi \u2014 ${widget.subject}' : 'Kawi',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (widget.mode == ChatMode.homework)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Foto soal',
              onPressed: _pickImage,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages
              Expanded(
                child: _buildMessageArea(chat, isWide, studentInitial),
              ),

              // Listening indicator banner
              if (_isListening)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: KSpace.sm,
                    horizontal: KSpace.md,
                  ),
                  color: const Color(0xFFE8F5E9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hearing, size: 18, color: KColors.green),
                      const SizedBox(width: KSpace.sm),
                      Text(
                        _speechLocale() == 'zh-CN'
                            ? 'Kawi mendengarkan... (Mandarin)'
                            : _speechLocale() == 'en-US'
                                ? 'Kawi mendengarkan... (English)'
                                : 'Kawi mendengarkan...',
                        style: const TextStyle(
                          color: KColors.greenDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Input bar
              _buildInputBar(chat, isWide),
            ],
          ),

          // Scroll to bottom FAB
          if (_showScrollToBottom)
            Positioned(
              bottom: 100 + MediaQuery.of(context).padding.bottom,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showScrollToBottom ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton.small(
                  backgroundColor: KColors.green,
                  foregroundColor: Colors.white,
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageArea(ChatService chat, bool isWide, String studentInitial) {
    if (chat.messages.isEmpty && !chat.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u{1F989}', style: TextStyle(fontSize: 64)),
            const SizedBox(height: KSpace.md),
            Text(
              'Kawi sedang bersiap...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    Widget listView = ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(isWide ? KSpace.lg : KSpace.md),
      itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chat.messages.length) {
          return _TypingIndicator();
        }
        final msg = chat.messages[index];
        // Skip the first user greeting
        if (index == 0) return const SizedBox.shrink();
        return _MessageBubble(
          message: msg,
          isWide: isWide,
          studentInitial: studentInitial,
          index: index,
        );
      },
    );

    if (isWide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: listView,
        ),
      );
    }

    return listView;
  }

  Widget _buildInputBar(ChatService chat, bool isWide) {
    Widget inputContent = Row(
      children: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate_outlined),
          color: KColors.green,
          onPressed: _pickImage,
          tooltip: 'Kirim foto',
        ),
        const SizedBox(width: KSpace.xs),

        // Mic button with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: _isListening
                      ? KColors.red
                      : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Colors.white
                        : _speechAvailable
                            ? KColors.green
                            : KColors.textLight,
                  ),
                  onPressed: chat.isLoading ? null : _toggleListening,
                  tooltip: _isListening
                      ? 'Berhenti mendengarkan'
                      : 'Bicara ke Kawi',
                ),
              ),
            );
          },
        ),
        const SizedBox(width: KSpace.xs),

        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: _inputHint(),
              hintStyle: const TextStyle(color: KColors.textLight),
              border: OutlineInputBorder(
                borderRadius: KRadius.xxl,
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF0F0F0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendText(),
            maxLines: 4,
            minLines: 1,
          ),
        ),
        const SizedBox(width: KSpace.sm),
        Container(
          decoration: const BoxDecoration(
            color: KColors.green,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: chat.isLoading ? null : _sendText,
          ),
        ),
      ],
    );

    Widget bar = Container(
      padding: EdgeInsets.fromLTRB(
        isWide ? KSpace.lg : 12,
        KSpace.sm,
        isWide ? KSpace.lg : 12,
        MediaQuery.of(context).padding.bottom + KSpace.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isWide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: inputContent,
              ),
            )
          : inputContent,
    );

    return bar;
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isWide;
  final String studentInitial;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.isWide,
    required this.studentInitial,
    required this.index,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  backgroundColor: KColors.green,
                  radius: 18,
                  child: Text('\u{1F989}', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: KSpace.sm),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: widget.isWide
                        ? 680
                        : MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? KColors.green : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: KColors.green.withAlpha(30),
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.imageBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            widget.message.imageBytes!,
                            width: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: KSpace.sm),
                      ],
                      if (isUser)
                        Text(
                          widget.message.content,
                          style:
                              const TextStyle(color: Colors.white, fontSize: 15),
                        )
                      else
                        MarkdownBody(
                          data: widget.message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 15, height: 1.5),
                            strong:
                                const TextStyle(fontWeight: FontWeight.bold),
                            code: TextStyle(
                              backgroundColor: Colors.grey[100],
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: KSpace.sm),
                CircleAvatar(
                  backgroundColor: KColors.blue,
                  radius: 18,
                  child: Text(
                    widget.studentInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: KColors.green,
            radius: 18,
            child: Text('\u{1F989}', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: KSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: KColors.green.withAlpha(30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Color.lerp(Colors.grey[300], Colors.grey[600], _controller.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
