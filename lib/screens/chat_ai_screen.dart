import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/chat_api_service.dart';
import 'app_locale.dart';

class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({super.key});

  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _inputScrollController = ScrollController();

  TextDirection _inputTextDirection = TextDirection.ltr;
  final ImagePicker _picker = ImagePicker();
  final ChatApiService _chatApiService = ChatApiService();

  SupabaseClient get sb => Supabase.instance.client;

  bool _loadingChat = true;
  String? _currentSessionId;
  List<Map<String, dynamic>> _chatSessions = [];

  bool _sending = false;
  List<Map<String, dynamic>> messages = [];

  static const int _historyLimit = 12;

  static const Color _background = Color(0xFF020617);
  static const Color _accent = Color(0xFF00F59B);
  static const Color _border = Color(0xFF06B6D4);
  static const Color _panel = Color(0xFF020617);
  static const Color _aiBubble = Color(0xFF0B1224);

  bool get _isArabic => localeNotifier.value.languageCode == 'ar';

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  TextAlign get _textAlign =>
      _isArabic ? TextAlign.right : TextAlign.left;

  String _t(String ar, String en) => _isArabic ? ar : en;

  String get _welcomeText =>
      _t('مرحبًا، كيف أستطيع مساعدتك؟', 'Hello, how can I help you?');

  String get _imageAnalysisText =>
      _t('حلّل هذه الصورة', 'Analyze this image');

  String get _languageSystemInstruction => _t(
        'أجب دائمًا بالعربية فقط وبأسلوب بسيط وواضح، وركّز على الأمن السيبراني والسلامة الرقمية.',
        'Always reply in English only, using a simple and clear style, and focus on cybersecurity and online safety.',
      );

  @override
  void initState() {
    super.initState();
    _loadInitialChat();
  }


  bool get _hasUserStartedChat => messages.any((m) => m['role'] == 'user');

  void _addWelcomeMessage() {
    messages.add({
      "role": "ai",
      "isWelcome": true,
      "timestamp": DateTime.now(),
    });
  }

  Future<void> _loadInitialChat() async {
    setState(() => _loadingChat = true);

    try {
      await _loadChatSessions();

      if (_chatSessions.isNotEmpty) {
        await _loadChatSession(_chatSessions.first['id'].toString(), closeSheet: false);
      } else {
        messages = [];
        _addWelcomeMessage();
      }
    } catch (e) {
      messages = [];
      _addWelcomeMessage();
      _showSnack(_t('تعذر تحميل المحادثات القديمة', 'Could not load old chats'));
    } finally {
      if (mounted) setState(() => _loadingChat = false);
    }
  }

  Future<void> _loadChatSessions() async {
    final user = sb.auth.currentUser;
    if (user == null) return;

    final data = await sb
        .from('chat_sessions')
        .select()
        .eq('user_id', user.id)
        .order('updated_at', ascending: false)
        .limit(30);

    _chatSessions = List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> _loadChatSession(String sessionId, {bool closeSheet = true}) async {
    final user = sb.auth.currentUser;
    if (user == null) return;

    final rows = await sb
        .from('chat_messages')
        .select()
        .eq('user_id', user.id)
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    final loadedMessages = List<Map<String, dynamic>>.from(rows as List).map((row) {
      return {
        'role': row['role'] == 'ai' ? 'ai' : 'user',
        'text': (row['content'] ?? '').toString(),
        'timestamp': DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
        'hasImage': row['has_image'] == true,
        'imagePath': row['image_path'],
      };
    }).toList();

    if (!mounted) return;

    setState(() {
      _currentSessionId = sessionId;
      messages = loadedMessages;
      if (messages.isEmpty) _addWelcomeMessage();
    });

    if (closeSheet && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    _scrollToBottom();
  }

  Future<void> _startNewChat() async {
    setState(() {
      _currentSessionId = null;
      messages = [];
      _addWelcomeMessage();
    });
    _scrollToBottom();
  }

  Future<void> _deleteChatSession(String sessionId) async {
    final user = sb.auth.currentUser;
    if (user == null) return;

    try {
      await sb
          .from('chat_sessions')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', user.id);

      await _loadChatSessions();

      if (!mounted) return;

      if (_currentSessionId == sessionId) {
        setState(() {
          _currentSessionId = null;
          messages = [];
          _addWelcomeMessage();
        });
      } else {
        setState(() {});
      }

      _showSnack(_t('تم حذف المحادثة', 'Chat deleted'));
    } catch (e) {
      if (mounted) {
        _showSnack(_t('تعذر حذف المحادثة', 'Could not delete chat'));
      }
    }
  }

  String _makeChatTitle(String text) {
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return _t('محادثة جديدة', 'New Chat');
    return clean.length <= 42 ? clean : '${clean.substring(0, 42)}...';
  }

  Future<String?> _ensureChatSession({String? firstMessage}) async {
    if (_currentSessionId != null) return _currentSessionId;

    final user = sb.auth.currentUser;
    if (user == null) return null;

    final created = await sb
        .from('chat_sessions')
        .insert({
          'user_id': user.id,
          'title': _makeChatTitle(firstMessage ?? ''),
        })
        .select()
        .single();

    final session = Map<String, dynamic>.from(created as Map);
    _currentSessionId = session['id'].toString();
    await _loadChatSessions();

    return _currentSessionId;
  }

  Future<void> _saveChatMessage({
    required String role,
    required String text,
    bool hasImage = false,
    String? imagePath,
  }) async {
    final user = sb.auth.currentUser;
    if (user == null) return;

    try {
      final sessionId = await _ensureChatSession(firstMessage: text);
      if (sessionId == null) return;

      await sb.from('chat_messages').insert({
        'session_id': sessionId,
        'user_id': user.id,
        'role': role,
        'content': text,
        'has_image': hasImage,
        'image_path': imagePath,
      });

      await sb
          .from('chat_sessions')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', sessionId)
          .eq('user_id', user.id);

      await _loadChatSessions();
    } catch (e) {
      if (mounted) {
        _showSnack(_t('تعذر حفظ الرسالة', 'Could not save message'));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputScrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _sendToBackend() async {
    final filtered = messages
        .where((m) =>
            (m['role'] == 'user' || m['role'] == 'ai') &&
            m['isWelcome'] != true)
        .toList();

    final slice = filtered.length <= _historyLimit
        ? filtered
        : filtered.sublist(filtered.length - _historyLimit);

    final chatHistory = <Map<String, String>>[
      {
        "role": "system",
        "content": _languageSystemInstruction,
      },
      ...slice.map((m) {
        final text = (m['text'] ?? '').toString().trim();
        final isImageMessage = m['hasImage'] == true;

        return {
          "role": m['role'] == 'ai' ? 'assistant' : 'user',
          "content": text.isEmpty && isImageMessage ? _imageAnalysisText : text,
        };
      }),
    ];

    final reply = await _chatApiService.sendMessage(chatHistory);
    return {"reply": reply};
  }

  Future<void> _sendWithTyping(
    Future<Map<String, dynamic>> Function() aiCall,
  ) async {
    setState(() {
      messages.add({"role": "typing"});
      _sending = true;
    });
    _scrollToBottom();

    String reply = '...';

    try {
      final aiResult = await aiCall();
      reply = (aiResult['reply'] ?? '...').toString();
    } catch (e) {
      reply = _t('حدث خطأ أثناء الاتصال بالخادم: $e', 'An error occurred while connecting to the server: $e');
    }

    if (!mounted) return;

    setState(() {
      messages.removeWhere((m) => m['role'] == 'typing');
      messages.add({
        "role": "ai",
        "text": reply,
        "timestamp": DateTime.now(),
      });
      _sending = false;
    });
    _scrollToBottom();
    await _saveChatMessage(role: 'ai', text: reply);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "text": trimmed,
        "timestamp": DateTime.now(),
      });
      _controller.clear();
    });
    _scrollToBottom();
    await _saveChatMessage(role: 'user', text: trimmed);

    await _sendWithTyping(_sendToBackend);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final caption = _controller.text.trim();
    _controller.clear();

    setState(() {
      messages.add({
        "role": "user",
        "text": caption.isEmpty ? _imageAnalysisText : caption,
        "timestamp": DateTime.now(),
        "hasImage": true,
        "imagePath": image.path,
      });
    });

    _scrollToBottom();
    await _saveChatMessage(
      role: 'user',
      text: caption.isEmpty ? _imageAnalysisText : caption,
      hasImage: true,
      imagePath: image.path,
    );
    await _sendWithTyping(_sendToBackend);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _keepInputCursorVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_inputScrollController.hasClients) return;

      _inputScrollController.animateTo(
        _inputScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
      );
    });
  }

  TextDirection _detectInputDirection(String text) {
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  void _handleInputChanged(String value) {
    final newDirection =
        value.trim().isEmpty ? _textDirection : _detectInputDirection(value);

    if (newDirection != _inputTextDirection) {
      setState(() => _inputTextDirection = newDirection);
    }

    _keepInputCursorVisible();
  }

  String _formatTime(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  String _formatSessionDate(dynamic value) {
    final dt = DateTime.tryParse((value ?? '').toString());
    if (dt == null) return '';
    return '${dt.day}/${dt.month} ${_formatTime(dt.toLocal())}';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: _panel.withOpacity(0.55),
        border: Border(
          bottom: BorderSide(color: _border.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_accent.withOpacity(0.8), _border.withOpacity(0.8)]),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.22), blurRadius: 14)],
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t('محادثة الذكاء الاصطناعي', 'AI Chat'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: _t('محادثة جديدة', 'New chat'),
            onPressed: _sending ? null : _startNewChat,
            icon: const Icon(Icons.add_comment_outlined, color: _accent),
          ),
          IconButton(
            tooltip: _t('المحادثات السابقة', 'Chat history'),
            onPressed: _showChatHistorySheet,
            icon: const Icon(Icons.history_rounded, color: _border),
          ),
        ],
      ),
    );
  }

  Future<void> _showChatHistorySheet() async {
    await _loadChatSessions();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _background,
      barrierColor: Colors.black.withOpacity(0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: _textDirection,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: _border.withOpacity(0.35))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t('المحادثات السابقة', 'Chat history'),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _startNewChat();
                        },
                        icon: const Icon(Icons.add, color: _accent, size: 18),
                        label: Text(_t('جديدة', 'New'), style: const TextStyle(color: _accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_chatSessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _t('لا توجد محادثات محفوظة بعد', 'No saved chats yet'),
                        style: TextStyle(color: Colors.white.withOpacity(0.65)),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _chatSessions.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.08)),
                        itemBuilder: (context, index) {
                          final session = _chatSessions[index];
                          final selected = session['id'].toString() == _currentSessionId;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: selected ? _accent : _aiBubble,
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: selected ? Colors.black : _border,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              (session['title'] ?? _t('محادثة جديدة', 'New Chat')).toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              _formatSessionDate(session['updated_at']),
                              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.85)),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: _aiBubble,
                                    title: Text(
                                      _t('حذف المحادثة؟', 'Delete chat?'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      _t('سيتم حذف هذه المحادثة ورسائلها نهائيًا.', 'This chat and its messages will be deleted permanently.'),
                                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: Text(_t('إلغاء', 'Cancel'), style: const TextStyle(color: _border)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  Navigator.pop(sheetContext);
                                  await _deleteChatSession(session['id'].toString());
                                }
                              },
                            ),
                            onTap: () => _loadChatSession(session['id'].toString()),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final bool showWatermark = !_hasUserStartedChat;

        return Directionality(
          textDirection: _textDirection,
          child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _background,
                    _background.withOpacity(0.95),
                    _background,
                  ],
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: showWatermark ? 0.12 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 56,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      const SizedBox(height: 10),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [_border, _accent],
                        ).createShader(rect),
                        child: const Text(
                          "CyberBreif",
                          style: TextStyle(
                            fontSize: 58,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t('مساعد الأمن السيبراني الذكي', 'AI Security Assistant'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildChatHeader(),
                  if (_loadingChat)
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];

                        if (msg['role'] == 'typing') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _aiBubble,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _border.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  _t('يكتب الآن...', 'Typing...'),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final isUser = msg['role'] == 'user';
                        final timestamp = msg['timestamp'] is DateTime
                            ? msg['timestamp'] as DateTime
                            : DateTime.now();

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.82,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? _border.withOpacity(0.95)
                                  : _aiBubble,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (isUser ? Colors.white : _border)
                                    .withOpacity(0.20),
                              ),
                              boxShadow: [
                                if (isUser)
                                  BoxShadow(
                                    color: _border.withOpacity(0.18),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg['hasImage'] == true &&
                                    (msg['imagePath'] ?? '').toString().isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(msg['imagePath'].toString()),
                                      width: 240,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (msg['hasImage'] == true &&
                                    (msg['imagePath'] ?? '').toString().isNotEmpty)
                                  const SizedBox(height: 8),
                                if (msg['text'] != null || msg['isWelcome'] == true)
                                  Text(
                                    msg['isWelcome'] == true
                                        ? _welcomeText
                                        : msg['text'].toString(),
                                    textAlign: _textAlign,
                                    textDirection: _textDirection,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.35,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(timestamp),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _panel.withOpacity(0.65),
                          border: Border(
                            top: BorderSide(
                              color: _border.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _border.withOpacity(0.25),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: TextField(
                                  controller: _controller,
                                  scrollController: _inputScrollController,
                                  textDirection: _controller.text.trim().isEmpty
                                      ? _textDirection
                                      : _inputTextDirection,
                                  textAlign: TextAlign.start,
                                  minLines: 1,
                                  maxLines: 3,
                                  keyboardType: TextInputType.multiline,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: _t('اكتب رسالتك...', 'Message'),
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: _handleInputChanged,
                                  onSubmitted: (v) => sendMessage(v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: _sending
                                    ? Colors.white.withOpacity(0.10)
                                    : _accent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  if (!_sending)
                                    BoxShadow(
                                      color: _accent.withOpacity(0.35),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _sending
                                      ? Icons.hourglass_empty
                                      : Icons.send,
                                  color: Colors.black,
                                ),
                                onPressed: _sending
                                    ? null
                                    : () => sendMessage(_controller.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        );
      },
    );
  }
}