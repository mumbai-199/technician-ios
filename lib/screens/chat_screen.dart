import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import '../widgets/localized_text.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.marketingTeamId,
    this.technicianId,
    this.title = 'Chat',
    this.onChatUpdated,
  });

  final int? marketingTeamId;
  final int? technicianId;
  final String title;
  final VoidCallback? onChatUpdated;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _threads = [];
  Timer? _pollingTimer;
  int _currentTechnicianId = 0;

  @override
  void initState() {
    super.initState();
    _loadThreads();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isRefreshing) {
        _loadThreads();
      }
    });
  }

  Future<void> _loadThreads() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final userData = await AuthService.getUserData();
      final technicianId = widget.technicianId ?? (userData['db_id'] ?? 0);
      _currentTechnicianId = technicianId;

      final result = await ApiService.getThreads(
        technicianId: technicianId > 0 ? technicianId : null,
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] is List) {
        setState(() {
          _threads.clear();
          _threads.addAll(List<Map<String, dynamic>>.from(result['data']));
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _isRefreshing = false;
    }
  }

  Future<void> _startDirectChat(Map<String, dynamic> contact) async {
    final userData = await AuthService.getUserData();
    final technicianId = widget.technicianId ?? (userData['db_id'] ?? 0);
    final contactId = int.tryParse((contact['id'] ?? 0).toString()) ?? 0;
    final contactType = (contact['type'] ?? '').toString();
    if (technicianId == 0 || contactId == 0 || contactType.isEmpty) return;

    final result = await ApiService.createThread(
      jobId: null,
      subject: (contact['name'] ?? 'Direct chat').toString(),
      type: 'general',
      participants: [
        {
          'participant_type': 'App\\Models\\Technician',
          'participant_id': technicianId,
          'role': 'member',
        },
        {
          'participant_type': contactType,
          'participant_id': contactId,
          'role': 'member',
        },
      ],
    );

    if (!mounted) return;
    if (result['success'] == true) {
      await _loadThreads();
      widget.onChatUpdated?.call();
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Unable to start chat')),
    );
  }

  Future<void> _openContactSheet() async {
    final userData = await AuthService.getUserData();
    final technicianId = widget.technicianId ?? (userData['db_id'] ?? 0);
    if (technicianId == 0) return;

    final result = await ApiService.getChatContacts(technicianId: technicianId);
    if (!mounted) return;
    final contacts = result['success'] == true && result['data'] is List
        ? List<Map<String, dynamic>>.from(result['data']).where((contact) {
            final type = (contact['type'] ?? '').toString();
            return type == 'App\\Models\\User' ||
                type == 'App\\Models\\MarketingTeam';
          }).toList()
        : const <Map<String, dynamic>>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Start chat',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text('Choose an admin or marketing user',
                  style: TextStyle(color: Color(0xFF607080))),
              const SizedBox(height: 18),
              ...contacts.map((contact) {
                final isAdmin = contact['type'] == 'App\\Models\\User';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: isAdmin
                        ? const Color(0xFFEAF0FF)
                        : const Color(0xFFE8F5E9),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.groups,
                      color: isAdmin
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                  title: Text((contact['name'] ?? 'Contact').toString()),
                  subtitle: Text((contact['label'] ??
                          (isAdmin ? 'Admin' : 'Marketing user'))
                      .toString()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    _startDirectChat(contact);
                  },
                );
              }),
              if (contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No admins or marketing users available.'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _threadTitle(Map<String, dynamic> thread) {
    final subject = (thread['subject'] ?? '').toString().trim();
    if (subject.isNotEmpty) return subject;

    final participants = List<Map<String, dynamic>>.from(
      (thread['participants'] ?? const [])
          .map((participant) => Map<String, dynamic>.from(participant)),
    );
    final names = participants
        .map((participant) => (participant['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .join(', ');
    return names.isEmpty ? 'Team conversation' : names;
  }

  String _threadPreview(Map<String, dynamic> thread) {
    final lastMessage = thread['last_message'];
    if (lastMessage is Map) {
      final message = (lastMessage['message'] ?? '').toString().trim();
      if (message.isNotEmpty) return message;
    }
    return 'No messages yet. Start the conversation.';
  }

  String _threadInitials(Map<String, dynamic> thread) {
    final words = _threadTitle(thread)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();
    return words.isEmpty
        ? 'C'
        : words.map((word) => word.substring(0, 1).toUpperCase()).join();
  }

  String _threadTime(Map<String, dynamic> thread) {
    final lastMessage = thread['last_message'];
    final value = lastMessage is Map
        ? (lastMessage['created_at'] ?? lastMessage['updated_at'])
        : thread['updated_at'];
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';

    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'NOW';
    if (difference.inHours < 1) return '${difference.inMinutes}M';
    if (difference.inDays < 1) return '${difference.inHours}H';
    if (difference.inDays < 7) return '${difference.inDays}D';
    return '${date.day}/${date.month}';
  }

  Color _threadAccent(int index) {
    const colors = [
      Color(0xFF0F766E),
      Color(0xFFD97706),
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFFBE123C),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final unreadThreads = _threads.where((thread) {
      final participants = List<Map<String, dynamic>>.from(
        (thread['participants'] ?? const [])
            .map((participant) => Map<String, dynamic>.from(participant)),
      );
      return participants.any((participant) =>
          participant['participant_type'] == 'App\\Models\\Technician' &&
          participant['participant_id'] == _currentTechnicianId &&
          (participant['unread_count'] as int? ?? 0) > 0);
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0F766E),
          onRefresh: _loadThreads,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 14, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173F3B),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF173F3B).withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'FIELD INBOX',
                                style: TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: Text.translate(context, 'Start chat'),
                              onPressed: _openContactSheet,
                              icon: const Icon(Icons.edit_rounded,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _HeaderStat(
                              value: _threads.length.toString(),
                              label: 'CONVERSATIONS',
                            ),
                            const SizedBox(width: 24),
                            _HeaderStat(
                              value: unreadThreads.toString(),
                              label: 'UNREAD',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                  ),
                )
              else if (_threads.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 54, color: Color(0xFF55706B)),
                          SizedBox(height: 16),
                          Text(
                            'Your inbox is clear',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'New conversations will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF55706B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  sliver: SliverList.builder(
                    itemCount: _threads.length,
                    itemBuilder: (context, index) {
                      final thread = _threads[index];
                      final participants = List<Map<String, dynamic>>.from(
                        (thread['participants'] ?? const []).map(
                            (participant) =>
                                Map<String, dynamic>.from(participant)),
                      );
                      final participantNames = participants
                          .map((participant) =>
                              (participant['name'] ?? 'Team member').toString())
                          .where((name) => name.isNotEmpty)
                          .join('  •  ');
                      final unreadCount = participants
                          .where((participant) =>
                              participant['participant_type'] ==
                                  'App\\Models\\Technician' &&
                              participant['participant_id'] ==
                                  _currentTechnicianId)
                          .fold<int>(
                              0,
                              (sum, participant) =>
                                  sum +
                                  (participant['unread_count'] as int? ?? 0));
                      final accent = _threadAccent(index);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () async {
                              final userData = await AuthService.getUserData();
                              final technicianId = widget.technicianId ??
                                  (userData['db_id'] ?? 0);
                              final threadId = thread['id'];
                              if (threadId == null) return;

                              final messagesResult =
                                  await ApiService.getThreadMessages(
                                threadId,
                                technicianId:
                                    technicianId > 0 ? technicianId : null,
                              );
                              if (!mounted) return;

                              if (messagesResult['success'] == true) {
                                await ApiService.markThreadAsRead(
                                  threadId: threadId,
                                  participantType: 'App\\Models\\Technician',
                                  participantId: technicianId,
                                );
                                if (!context.mounted) return;
                                final messages =
                                    (messagesResult['data'] as List?) ??
                                        const [];
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => _ChatThreadSheet(
                                    threadId: threadId,
                                    title: _threadTitle(thread),
                                    messages: List<Map<String, dynamic>>.from(
                                        messages),
                                    senderType: 'App\\Models\\Technician',
                                    senderId: technicianId,
                                    onMessageSent: _loadThreads,
                                  ),
                                );
                                await _loadThreads();
                                widget.onChatUpdated?.call();
                              }
                            },
                            child: Ink(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FA),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8795A5)
                                        .withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(3, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.13),
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: Text(
                                      _threadInitials(thread),
                                      style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _threadTitle(thread),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w800),
                                              ),
                                            ),
                                            Text(
                                              _threadTime(thread),
                                              style: TextStyle(
                                                  color: accent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _threadPreview(thread),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Color(0xFF607080),
                                              fontSize: 13,
                                              height: 1.35),
                                        ),
                                        const SizedBox(height: 9),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.people_alt_outlined,
                                                size: 13,
                                                color: Color(0xFF82909D)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                participantNames.isEmpty
                                                    ? 'Team conversation'
                                                    : participantNames,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Color(0xFF82909D),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                            if (unreadCount > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                    color: accent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            9)),
                                                child: Text(
                                                  unreadCount.toString(),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Color(0xFFB7D6CF),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ],
    );
  }
}

class _ChatThreadSheet extends StatefulWidget {
  const _ChatThreadSheet({
    required this.threadId,
    required this.title,
    required this.messages,
    required this.senderType,
    required this.senderId,
    required this.onMessageSent,
  });

  final int threadId;
  final String title;
  final List<Map<String, dynamic>> messages;
  final String senderType;
  final int senderId;
  final Future<void> Function() onMessageSent;

  @override
  State<_ChatThreadSheet> createState() => _ChatThreadSheetState();
}

class _ChatThreadSheetState extends State<_ChatThreadSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final result = await ApiService.sendMessage(
      threadId: widget.threadId,
      senderType: widget.senderType,
      senderId: widget.senderId,
      message: text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _controller.clear();
      await widget.onMessageSent();
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Unable to send message')),
      );
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SafeArea(
        minimum: EdgeInsets.zero,
        child: Container(
          height: mediaQuery.size.height * 0.86,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F6F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF173F3B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFA7F3D0).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.forum_rounded,
                              color: Color(0xFFA7F3D0), size: 23),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              const Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 7, color: Color(0xFFA7F3D0)),
                                  SizedBox(width: 5),
                                  Text('Conversation',
                                      style: TextStyle(
                                          color: Color(0xFFB7D6CF),
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: Text.translate(context, 'Close'),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mark_chat_unread_outlined,
                                size: 42, color: Color(0xFF78908B)),
                            SizedBox(height: 12),
                            Text('No messages yet',
                                style: TextStyle(
                                    color: Color(0xFF55706B),
                                    fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Send an update to begin.',
                                style: TextStyle(
                                    color: Color(0xFF829A95), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        itemCount: widget.messages.length,
                        itemBuilder: (context, index) {
                          final message = widget.messages[index];
                          final isMe =
                              (message['sender_id'] ?? 0) == widget.senderId;
                          final messageText =
                              (message['message'] ?? '').toString();
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
                              constraints: BoxConstraints(
                                  maxWidth: mediaQuery.size.width * 0.78),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF0F766E)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 5),
                                  bottomRight: Radius.circular(isMe ? 5 : 18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF60756F)
                                        .withValues(alpha: 0.1),
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(messageText,
                                      style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : const Color(0xFF233633),
                                          fontSize: 14,
                                          height: 1.35)),
                                  const SizedBox(height: 5),
                                  Text(isMe ? 'You' : 'Team member',
                                      style: TextStyle(
                                          color: isMe
                                              ? const Color(0xFFC7F8E4)
                                              : const Color(0xFF829A95),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 10,
                        offset: Offset(0, -3)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: Text.translate(context, 'Write an update...'),
                          filled: true,
                          fillColor: const Color(0xFFF2F6F5),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isSending ? null : _sendMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: EdgeInsets.zero,
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
