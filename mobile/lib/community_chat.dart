part of 'main.dart';

const _communityRulesKey = 'community_rules_accepted_v1';

String _chatTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  final now = DateTime.now();
  final clock = '${two(time.hour)}:${two(time.minute)}';
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return clock;
  }
  return '${two(time.day)}/${two(time.month)} $clock';
}

class _FinflowCommunityTab extends StatefulWidget {
  const _FinflowCommunityTab({
    required this.preset,
    this.preview = false,
    super.key,
  });

  final DemoPreset preset;

  /// Static backdrop shown blurred behind the sign-in prompt.
  final bool preview;

  @override
  State<_FinflowCommunityTab> createState() => _FinflowCommunityTabState();
}

class _FinflowCommunityTabState extends State<_FinflowCommunityTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _events;
  Timer? _pollTimer;
  bool _loading = true;
  bool _loadingOlder = false;
  bool _hasMore = false;
  bool _sending = false;
  String? _error;

  static final _previewMessages = [
    ChatMessage(
      id: 'preview-1',
      body: 'Chào mừng bạn đến khung chat chung của cộng đồng Diện Chẩn.',
      createdAt: DateTime(2026, 1, 1, 9, 20),
      isMine: false,
      author: const CommunityMember(
        id: 'preview',
        fullName: 'Cộng đồng Diện Chẩn',
        country: 'Việt Nam',
      ),
    ),
    ChatMessage(
      id: 'preview-2',
      body: 'Đăng nhập để đặt câu hỏi và chia sẻ kinh nghiệm.',
      createdAt: DateTime(2026, 1, 1, 9, 24),
      isMine: true,
      author: const CommunityMember(id: 'me', fullName: 'Bạn', country: ''),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preview) {
      _messages.addAll(_previewMessages);
      _loading = false;
      return;
    }
    _events = _realtime.events.listen(_onEvent);
    _scrollController.addListener(_onScroll);
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_realtime.connected) _fetchLatest();
    });
    _load();
  }

  @override
  void dispose() {
    _events?.cancel();
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (messages, hasMore) = await _api.chatMessages();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _hasMore = hasMore;
      });
      _scrollToBottom(animate: false);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchLatest() async {
    try {
      final (messages, _) = await _api.chatMessages();
      if (!mounted) return;
      final known = _messages.map((message) => message.id).toSet();
      final fresh = messages.where((message) => !known.contains(message.id));
      if (fresh.isEmpty) return;
      setState(() => _messages.addAll(fresh));
      _scrollToBottom();
    } catch (_) {
      // Polling is a fallback; ignore transient failures.
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels < 80 && _hasMore && !_loadingOlder) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    if (_messages.isEmpty) return;
    setState(() => _loadingOlder = true);
    try {
      final previousExtent = _scrollController.position.maxScrollExtent;
      final (older, hasMore) = await _api.chatMessages(
        before: _messages.first.id,
      );
      if (!mounted) return;
      setState(() {
        _messages.insertAll(0, older);
        _hasMore = hasMore;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final added =
            _scrollController.position.maxScrollExtent - previousExtent;
        _scrollController.jumpTo(_scrollController.position.pixels + added);
      });
    } catch (_) {
      // Keep the current page; the user can scroll up again to retry.
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  void _onEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'chat':
        final message = ChatMessage.fromJson(
          event['message'] as Map<String, dynamic>,
        );
        if (_messages.any((item) => item.id == message.id)) return;
        final atBottom =
            !_scrollController.hasClients ||
            _scrollController.position.extentAfter < 120;
        setState(() => _messages.add(message));
        if (atBottom || message.isMine) _scrollToBottom();
      case 'chat_hidden':
        setState(
          () => _messages.removeWhere((item) => item.id == event['messageId']),
        );
      case 'chat_user_removed':
        setState(
          () => _messages.removeWhere(
            (item) => item.author.id == event['userId'],
          ),
        );
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<bool> _acceptRules() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_communityRulesKey) == true) return true;
    if (!mounted) return false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quy tắc cộng đồng'),
        content: const SingleChildScrollView(
          child: Text(
            '• Tôn trọng mọi thành viên, không dùng ngôn từ xúc phạm, quấy rối hay phân biệt.\n'
            '• Không quảng cáo, spam hoặc chia sẻ nội dung phản cảm.\n'
            '• Thông tin sức khỏe chỉ mang tính tham khảo, không thay thế chẩn đoán của bác sĩ.\n'
            '• Tin nhắn vi phạm sẽ bị ẩn; tài khoản vi phạm nhiều lần có thể bị khóa.\n\n'
            'Bạn có thể báo cáo tin nhắn hoặc chặn thành viên bằng cách nhấn giữ vào tin nhắn.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tôi đồng ý'),
          ),
        ],
      ),
    );
    if (accepted != true) return false;
    await preferences.setBool(_communityRulesKey, true);
    return true;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending || widget.preview) return;
    if (!await _acceptRules()) return;
    setState(() => _sending = true);
    try {
      final message = await _api.sendChat(text);
      if (!mounted) return;
      _messageController.clear();
      if (!_messages.any((item) => item.id == message.id)) {
        setState(() => _messages.add(message));
      }
      _scrollToBottom();
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openOnlineUsers(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _OnlineUsersSheet(onBlocked: _removeAuthor),
    );
  }

  void _removeAuthor(String userId) {
    setState(() => _messages.removeWhere((item) => item.author.id == userId));
  }

  Future<void> _openMessageActions(ChatMessage message) async {
    if (widget.preview) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Sao chép'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            if (message.isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xóa tin nhắn'),
                onTap: () => Navigator.pop(context, 'delete'),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Báo cáo tin nhắn'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('Xem ${message.author.fullName}'),
                onTap: () => Navigator.pop(context, 'member'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.body));
      case 'delete':
        try {
          await _api.deleteChat(message.id);
          setState(
            () => _messages.removeWhere((item) => item.id == message.id),
          );
        } catch (error) {
          if (mounted) _showApiError(context, error);
        }
      case 'report':
        await _report(message);
      case 'member':
        if (await _showCommunityMember(context, message.author)) {
          _removeAuthor(message.author.id);
        }
    }
  }

  Future<void> _report(ChatMessage message) async {
    const reasons = [
      'Spam hoặc quảng cáo',
      'Ngôn từ xúc phạm, quấy rối',
      'Thông tin sức khỏe sai lệch',
      'Nội dung phản cảm',
      'Lý do khác',
    ];
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Báo cáo tin nhắn'),
        children: reasons
            .map(
              (reason) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, reason),
                child: Text(reason),
              ),
            )
            .toList(),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await _api.reportChat(message.id, reason);
      if (!mounted) return;
      setState(() => _messages.removeWhere((item) => item.id == message.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cảm ơn bạn. Tin nhắn đã được ẩn và gửi tới quản trị viên.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showApiError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('finflow-community'),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF211610),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F266),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Color(0xFF213319),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat cộng đồng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mở cho tất cả người dùng',
                      style: TextStyle(
                        color: Color(0xFFD9CEC5),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: const Color(0xFF2E644D),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.preview
                      ? null
                      : () => _openOnlineUsers(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF7CFF9C),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 7, height: 7),
                        ),
                        const SizedBox(width: 6),
                        ListenableBuilder(
                          listenable: _realtime,
                          builder: (context, _) => Text(
                            '${widget.preview ? 0 : _realtime.online.length} online',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
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
        Expanded(child: _buildMessages()),
        SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7DCD1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Nhắn tin vào cộng đồng...',
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: const Color(0xFFB55238),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _sending ? null : _sendMessage,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessages() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa có tin nhắn nào. Hãy gửi lời chào đầu tiên tới cộng đồng!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      itemCount: _messages.length + (_loadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (_loadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final message = _messages[index - (_loadingOlder ? 1 : 0)];
        return _CommunityChatBubble(
          message: message,
          onLongPress: () => _openMessageActions(message),
          onAuthorTap: () async {
            if (widget.preview) return;
            if (await _showCommunityMember(context, message.author)) {
              _removeAuthor(message.author.id);
            }
          },
        );
      },
    );
  }
}

class _OnlineUsersSheet extends StatelessWidget {
  const _OnlineUsersSheet({required this.onBlocked});

  final ValueChanged<String> onBlocked;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SizedBox(
      height: height,
      child: ListenableBuilder(
        listenable: _realtime,
        builder: (context, _) {
          final users = _realtime.online;
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4D4C4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Người dùng đang online',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      '${users.length} người',
                      style: const TextStyle(
                        color: Color(0xFF8A6E5C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0E6DC)),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Text(
                          _realtime.connected
                              ? 'Chưa có ai online.'
                              : 'Đang kết nối máy chủ...',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 72,
                          color: Color(0xFFF4EBE3),
                        ),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isMe = user.id == _currentUserProfile.value?.id;
                          return ListTile(
                            onTap: () async {
                              if (await _showCommunityMember(context, user)) {
                                onBlocked(user.id);
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF4E4D4),
                              foregroundColor: const Color(0xFFB55238),
                              child: Text(
                                user.fullName.isEmpty
                                    ? '?'
                                    : user.fullName.characters.first,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              isMe ? '${user.fullName} (bạn)' : user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              user.country.isEmpty
                                  ? 'Chưa cập nhật quốc gia'
                                  : user.country,
                              style: const TextStyle(color: Color(0xFF8A6E5C)),
                            ),
                            trailing: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2E644D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SizedBox(width: 8, height: 8),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Color(0xFF2E644D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommunityChatBubble extends StatelessWidget {
  const _CommunityChatBubble({
    required this.message,
    required this.onLongPress,
    required this.onAuthorTap,
  });

  final ChatMessage message;
  final VoidCallback onLongPress;
  final VoidCallback onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final author = message.author.fullName;
    final bubbleColor = isMine ? const Color(0xFFB55238) : Colors.white;
    final textColor = isMine ? Colors.white : const Color(0xFF2C1A12);
    final mutedColor = isMine
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF8C7B70);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            Semantics(
              button: true,
              label: 'Xem thông tin $author',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAuthorTap,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE9D8CA),
                  child: Text(
                    author.isEmpty ? '?' : author.characters.first,
                    style: const TextStyle(
                      color: Color(0xFF7A3F2C),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 292),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 5),
                    bottomRight: Radius.circular(isMine ? 5 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMine) ...[
                      Text(
                        message.author.country.isEmpty
                            ? author
                            : '$author · ${message.author.country}',
                        style: const TextStyle(
                          color: Color(0xFF8B4A31),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      message.body,
                      style: TextStyle(
                        color: textColor,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _chatTime(message.createdAt),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
