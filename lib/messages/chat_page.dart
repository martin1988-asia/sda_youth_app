import 'dart:io' as io; // ✅ FIXED
import 'package:flutter/foundation.dart'; // ✅ ADDED
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../services/private_chat_service.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  AudioPlayer? player; // ✅ FIX

  String? _playingUrl;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isMounted = true;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      player = AudioPlayer(); // ✅ FIX
    }

    PrivateChatService.markAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _isMounted = false;
    controller.dispose();
    player?.dispose(); // ✅ FIX

    PrivateChatService.setTyping(widget.conversationId, false);

    super.dispose();
  }

  /* =============================
     ✅ SEND MESSAGE
  ============================== */
  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    await PrivateChatService.sendMessage(widget.conversationId, text);

    if (_isMounted) {
      PrivateChatService.setTyping(widget.conversationId, false);
    }
  }

  /* =============================
     ✅ AUDIO CACHE + PLAY
  ============================== */
  Future<io.File?> _getLocalFile(String url) async {
    // ✅ FIX
    if (kIsWeb) return null; // ✅ ADD

    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/${url.hashCode}.m4a');

    if (await file.exists()) return file;

    final res = await http.get(Uri.parse(url));
    await file.writeAsBytes(res.bodyBytes);

    return file;
  }

  Future<void> _play(String url) async {
    if (kIsWeb || player == null) return; // ✅ ADD

    if (_playingUrl == url) {
      await player!.stop();
      setState(() => _playingUrl = null);
      return;
    }

    setState(() => _playingUrl = url);

    try {
      final file = await _getLocalFile(url);
      if (file != null) {
        await player!.play(DeviceFileSource(file.path));
      } else {
        await player!.play(UrlSource(url));
      }
    } catch (_) {
      await player!.play(UrlSource(url));
    }

    player!.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    player!.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });

    player!.onPlayerComplete.listen((_) {
      setState(() {
        _playingUrl = null;
        _position = Duration.zero;
      });
    });
  }

  void _seek(double dx, double width) {
    if (kIsWeb || player == null) return; // ✅ ADD

    if (_duration.inMilliseconds == 0) return;

    final percent = (dx / width).clamp(0, 1);
    player!.seek(_duration * percent);
  }

  /* =============================
     ✅ WAVEFORM
  ============================== */
  Widget _waveform(List amps, bool isMe) {
    return Row(
      children: amps.take(35).map((e) {
        final val = (e as num).toDouble();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 3,
          height: (val * 28).clamp(4, 32),
          color: isMe ? Colors.black : AppTheme.textPrimary,
        );
      }).toList(),
    );
  }

  /* =============================
     ✅ REACTIONS
  ============================== */
  Future<void> _react(String id, String emoji) async {
    final ref = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(id);

    await ref.set({'reactions.$uid': emoji}, SetOptions(merge: true));
  }

  void _openReactions(String id) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ["❤️", "🔥", "😂", "👍"]
            .map(
              (e) => GestureDetector(
                onTap: () {
                  _react(id, e);
                  Navigator.pop(context);
                },
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
            )
            .toList(),
      ),
    );
  }

  /* =============================
     ✅ AVATAR
  ============================== */
  Widget _avatar() {
    final hasImage = widget.otherUserPhoto.startsWith('http');

    return CircleAvatar(
      backgroundColor: Colors.grey[800],
      backgroundImage: hasImage ? NetworkImage(widget.otherUserPhoto) : null,
      child: !hasImage
          ? const Icon(Icons.person, color: AppTheme.textSecondary)
          : null,
    );
  }

  /* =============================
     ✅ HEADER STATUS
  ============================== */
  Widget _status() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final data = snap.data!.data() as Map<String, dynamic>;
        final online = data['online'] == true;
        final ts = data['lastSeen'] as Timestamp?;

        return Text(
          online
              ? "Online"
              : ts != null
              ? "Last seen ${ts.toDate().hour}:${ts.toDate().minute}"
              : "",
          style: TextStyle(
            fontSize: 12,
            color: online ? Colors.green : AppTheme.textMuted,
          ),
        );
      },
    );
  }

  /* =============================
     ✅ CHAT BUBBLE
  ============================== */
  Widget _bubble(String id, Map data) {
    final isMe = data['senderId'] == uid;
    final isRead = data['read'] == true;
    final delivered = data['delivered'] == true;

    final audio = data['audioUrl'];
    final text = data['text'];
    final reactions = data['reactions'] ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _openReactions(id),

            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : AppTheme.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
              ),

              child:
                  audio != null &&
                      !kIsWeb // ✅ ONLY CHANGE
                  ? LayoutBuilder(
                      builder: (ctx, c) => GestureDetector(
                        onHorizontalDragUpdate: (d) =>
                            _seek(d.localPosition.dx, c.maxWidth),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _playingUrl == audio
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: () => _play(audio),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  _waveform(data['waveform'] ?? [], isMe),
                                  LinearProgressIndicator(
                                    value: _duration.inMilliseconds == 0
                                        ? 0
                                        : _position.inMilliseconds /
                                              _duration.inMilliseconds,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Text(
                      text ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.black : AppTheme.textPrimary,
                      ),
                    ),
            ),
          ),

          if (reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                children: reactions.values.map<Widget>((e) => Text(e)).toList(),
              ),
            ),

          if (isMe)
            Icon(
              isRead
                  ? Icons.done_all
                  : delivered
                  ? Icons.done_all
                  : Icons.check,
              size: 16,
              color: isRead ? AppTheme.primary : AppTheme.textMuted,
            ),
        ],
      ),
    );
  }

  /* =============================
     ✅ UI
  ============================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,

      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Row(
          children: [
            _avatar(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                _status(),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ✅ TYPING
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: PrivateChatService.typingStream(widget.conversationId),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox();

              final typing = snap.data!.docs.any(
                (d) => d.id != uid && d.data()['typing'] == true,
              );

              if (!typing) return const SizedBox();

              return const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Typing...",
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              );
            },
          ),

          // ✅ CHAT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: PrivateChatService.streamMessages(widget.conversationId),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snap.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final doc = msgs[i];
                    return _bubble(doc.id, doc.data());
                  },
                );
              },
            ),
          ),

          // ✅ INPUT
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: (v) => PrivateChatService.setTyping(
                        widget.conversationId,
                        v.isNotEmpty,
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primary),
                    onPressed: send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
