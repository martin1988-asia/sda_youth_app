// ✅ FULL FILE — STRUCTURE PRESERVED, ONLY SAFE FIX APPLIED

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/theme.dart';
import '../services/private_chat_service.dart';
import 'chat_page.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  bool _isValidImage(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bg,

      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text(
          "Messages",
          style: TextStyle(color: AppTheme.textPrimary),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.chat, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _UserPickerPage()),
          );
        },
      ),

      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: PrivateChatService.inboxStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data!;

          if (conversations.isEmpty) {
            return const Center(
              child: Text(
                "No conversations yet",
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          // ✅ keeps layout from stretching edge to edge
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: conversations.length,
                itemBuilder: (_, i) {
                  final doc = conversations[i];
                  final data = doc.data();

                  final participants = List<String>.from(data['participants']);

                  final otherUserId = participants.firstWhere(
                    (id) => id != currentUid,
                  );

                  final unreadMap =
                      data['unreadCount'] as Map<String, dynamic>?;

                  final unread = unreadMap?[currentUid] ?? 0;

                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get(),
                    builder: (_, userSnap) {
                      String name = "User";
                      String photo = "";

                      if (userSnap.hasData && userSnap.data!.data() != null) {
                        final userData = userSnap.data!.data()!;
                        name = userData['name'] ?? "User";
                        photo = userData['profileImageUrl'] ?? "";
                      }

                      final hasImage = _isValidImage(photo);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        child: Material(
                          color: AppTheme.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 2, // ✅ replaces boxShadow safely

                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),

                            onTap: () async {
                              final conversationId =
                                  await PrivateChatService.getOrCreateConversation(
                                    otherUserId,
                                  );

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    conversationId: conversationId,
                                    otherUserId: otherUserId,
                                    otherUserName: name,
                                    otherUserPhoto: photo,
                                  ),
                                ),
                              );
                            },

                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),

                              // ✅ FIX: removed background decoration ONLY
                              // (this prevents DecoratedBox conflict)
                              // keeping container for structure + spacing
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),

                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: hasImage
                                      ? NetworkImage(photo)
                                      : null,
                                  child: !hasImage
                                      ? const Icon(
                                          Icons.person,
                                          color: AppTheme.textSecondary,
                                        )
                                      : null,
                                ),

                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                subtitle: Text(
                                  data['lastMessage'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),

                                trailing: unread > 0
                                    ? Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          unread > 9 ? '9+' : unread.toString(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ✅ USER PICKER PAGE — FULLY UNCHANGED

class _UserPickerPage extends StatelessWidget {
  const _UserPickerPage();

  bool _isValidImage(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bg,

      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text(
          "Start New Chat",
          style: TextStyle(color: AppTheme.textPrimary),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final doc = users[i];

              if (doc.id == currentUid) {
                return const SizedBox();
              }

              final data = doc.data();

              final name = data['name'] ?? "User";
              final photo = data['profileImageUrl'] ?? "";

              final hasImage = _isValidImage(photo);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                child: Material(
                  color: AppTheme.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),

                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),

                    onTap: () async {
                      final convId =
                          await PrivateChatService.getOrCreateConversation(
                            doc.id,
                          );

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            conversationId: convId,
                            otherUserId: doc.id,
                            otherUserName: name,
                            otherUserPhoto: photo,
                          ),
                        ),
                      );
                    },

                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[800],
                        backgroundImage: hasImage ? NetworkImage(photo) : null,
                        child: !hasImage
                            ? const Icon(
                                Icons.person,
                                color: AppTheme.textSecondary,
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
