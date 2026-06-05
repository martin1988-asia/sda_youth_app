import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

import '../features/chat/users_list_page.dart';
import '../features/profile/public_profile_page.dart';
import '../features/reels/reels_page.dart';
import '../core/theme.dart';
import '../widgets/post_card.dart';
import '../widgets/app_drawer.dart';
import '../services/post_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _showFollowing = true;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);

    FirebaseAnalytics.instance.logEvent(
      name: "nav_tab_switch",
      parameters: {"index": index},
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Text(
            "Identity Verification Required",
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      drawer: const AppDrawer(),

      appBar: _currentIndex == 0
          ? null
          : AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: AppTheme.textPrimary),
              title: Text(
                _currentIndex == 1 ? "Home" : "Inbox",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                if (_currentIndex == 1)
                  IconButton(
                    icon: Icon(
                      _showFollowing ? Icons.people : Icons.public,
                      color: AppTheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFollowing = !_showFollowing;
                      });
                    },
                  ),

                if (_currentIndex == 2)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UsersListPage(),
                        ),
                      );
                    },
                  ),

                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.textPrimary),
                  onPressed: () => context.push('/search'),
                ),

                _notificationBadge(user.uid),
              ],
            ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          ReelsPage(isVisible: _currentIndex == 0),
          _FeedTab(showFollowing: _showFollowing),
          const _InboxTab(),
        ],
      ),

      // ✅ ✅ PRO-LEVEL BOTTOM NAV
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.play_circle),
              label: '',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),

            BottomNavigationBarItem(
              icon: StreamBuilder<int>(
                stream: _unreadCountStream(user.uid),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_rounded),

                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationBadge(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (_, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: AppTheme.textPrimary,
              ),
              onPressed: () => context.push('/notifications'),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ✅✅✅ FINAL PRODUCTION UNREAD SYSTEM (FULL REAL-TIME)
Stream<int> _unreadCountStream(String uid) {
  final unreadMessagesStream = FirebaseFirestore.instance
      .collectionGroup('messages')
      .where('receiverId', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  final unreadNotificationsStream = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  return unreadMessagesStream.switchMap((messageCount) {
    return unreadNotificationsStream.map((notifCount) {
      return messageCount + notifCount;
    });
  });
}

class _FeedTab extends StatelessWidget {
  final bool showFollowing;
  const _FeedTab({required this.showFollowing});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: PostService.smartFeedStream(user!.uid),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            List docs = snap.data!;

            if (showFollowing) {
              docs = docs.where((doc) {
                final data = doc.data();
                final authorId = data['authorId'];

                if (authorId == user.uid) return true;

                if (data.containsKey('visibleTo')) {
                  final List visibleTo = data['visibleTo'] ?? [];
                  return visibleTo.contains(user.uid);
                }

                return true;
              }).toList();
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              itemCount: docs.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) return const _Composer();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: PostCard(
                    key: ValueKey(docs[i - 1].id),
                    postId: docs[i - 1].id,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InboxTab extends StatelessWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastTimestamp', descending: true) // ✅ proper ordering
          .snapshots(),
      builder: (_, chatSnap) {
        if (!chatSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = chatSnap.data!.docs;

        if (chats.isEmpty) {
          return const Center(
            child: Text(
              "No conversations yet",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: chats.length,
          itemBuilder: (_, i) {
            final chatDoc = chats[i];
            final chatId = chatDoc.id;
            final data = chatDoc.data();

            final participants = List<String>.from(data['participants'] ?? []);

            final otherUserId = participants.firstWhere((id) => id != userId);

            return _ChatTile(
              chatId: chatId,
              otherUserId: otherUserId,
              currentUserId: userId,
            );
          },
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String currentUserId;

  const _ChatTile({
    required this.chatId,
    required this.otherUserId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get(),
      builder: (_, userSnap) {
        final userData = userSnap.data?.data();

        final name = userData?['name'] ?? "User";
        final photo = userData?['userPhotoUrl'];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (_, msgSnap) {
            if (!msgSnap.hasData) {
              return const ListTile(
                title: Text(
                  "Loading...",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            Map<String, dynamic>? msg;

            if (msgSnap.data!.docs.isNotEmpty) {
              msg = msgSnap.data!.docs.first.data();
            }

            final text = msg?['text'] ?? "No messages yet";
            final isMe = msg?['senderId'] == currentUserId;
            final isRead = msg?['isRead'] ?? false;
            final ts = msg?['timestamp'] as Timestamp?;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),

              // ✅ Avatar
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white12,
                backgroundImage:
                    (photo != null && photo.toString().startsWith("http"))
                    ? NetworkImage(photo)
                    : null,
                child: photo == null
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),

              // ✅ Name
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // ✅ Last message
              subtitle: Row(
                children: [
                  if (isMe)
                    Icon(
                      isRead ? Icons.done_all : Icons.check,
                      size: 14,
                      color: isRead ? Colors.blue : Colors.grey,
                    ),

                  if (isMe) const SizedBox(width: 4),

                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: (!isRead && !isMe)
                            ? Colors.white
                            : Colors.white54,
                        fontWeight: (!isRead && !isMe)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ Right side (time + unread dot)
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (ts != null)
                    Text(
                      TimeOfDay.fromDateTime(ts.toDate()).format(context),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),

                  const SizedBox(height: 4),

                  if (!isRead && !isMe)
                    const Icon(Icons.circle, size: 10, color: Colors.redAccent),
                ],
              ),

              // ✅ NAVIGATION (final system)
              onTap: () {
                context.push('/chat', extra: otherUserId);
              },
            );
          },
        );
      },
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .limit(20)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snap.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              itemCount: users.length,
              itemBuilder: (_, i) {
                final doc = users[i];
                final data = doc.data();

                final name = data['name'] ?? "User";
                final photoUrl = data['userPhotoUrl'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicProfilePage(userId: doc.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white12,
                              backgroundImage:
                                  (photoUrl != null &&
                                      photoUrl.toString().startsWith("http"))
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "View profile",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.white38,
                            ),
                          ],
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
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: () => context.push('/create_post'),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 18, child: Icon(Icons.edit, size: 18)),
                SizedBox(width: 14),
                Text(
                  "What's on your heart today?",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
