// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:io';

import 'followers_page.dart';
import 'following_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';

import '../../services/follow_service.dart';
import '../../services/private_chat_service.dart';
import '../../messages/chat_page.dart';
import '../../widgets/post_card.dart';
import '../../core/theme.dart';
import '../reels/reels_page.dart';

class ProfileViewPage extends StatefulWidget {
  final String userId;

  const ProfileViewPage({super.key, required this.userId});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  bool _uploading = false;

  int _selectedTab = 0; // 0 = Posts, 1 = Reels

  final Map<String, Uint8List> _thumbnailCache = {}; // ✅ cache
  final Map<String, VideoPlayerController> _videoControllers = {};



Future<void> _updateProfileImage() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.uid != widget.userId) return;

  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery);

  if (picked == null) return;

  if (!mounted) return;
  setState(() => _uploading = true);

  try {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    // ✅ WEB SAFE
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();

      await ref.putData(bytes).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception("Upload timeout (Check Firebase Storage)");
        },
      );
    } else {
      final file = File(picked.path);

      await ref.putFile(file).timeout(
        const Duration(seconds: 20),
      );
    }

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'userPhotoUrl': url,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated ✅")),
    );

  } catch (e) {
    debugPrint("UPLOAD ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload failed: $e")),
    );
  } finally {
    // ✅ ALWAYS RESET
    if (mounted) {
      setState(() => _uploading = false);
    }
  }
}



  Future<Uint8List?> _getThumbnail(String videoUrl) async {
    try {
      // ✅ CHECK CACHE FIRST
      if (_thumbnailCache.containsKey(videoUrl)) {
        return _thumbnailCache[videoUrl];
      }

      final bytes = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        quality: 50,
      );

      // ✅ SAVE TO CACHE
      if (bytes != null) {
        _thumbnailCache[videoUrl] = bytes;
      }

      return bytes;
    } catch (e) {
      return null;
    }
  }

  Future<VideoPlayerController> _getController(String url) async {
    if (_videoControllers.containsKey(url)) {
      return _videoControllers[url]!;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.setVolume(0); // ✅ mute
    controller.setLooping(true);

    _videoControllers[url] = controller;
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.userId;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final data = snap.data!.data() ?? {};

          final imageUrl = data['userPhotoUrl'];
          final name = data['name'] ?? 'User';
          final bio = data['bio'] ?? '';
          final followersCount = data['followersCount'] ?? 0;
          final followingCount = data['followingCount'] ?? 0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: CustomScrollView(
                slivers: [
                  /// ✅ PROFILE HEADER CARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            /// AVATAR
                            GestureDetector(
                              onTap: isOwner ? _updateProfileImage : null,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white12,
                                    backgroundImage:
                                        (imageUrl != null &&
                                            imageUrl.toString().startsWith(
                                              'http',
                                            ))
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl == null
                                        ? const Icon(Icons.person, size: 40)
                                        : null,
                                  ),
                                  if (_uploading)
                                    const CircularProgressIndicator(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            /// NAME
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// BIO
                            Text(
                              bio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),

                            const SizedBox(height: 16),

                            /// STATS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _countItem("Followers", followersCount),
                                const SizedBox(width: 20),
                                _countItem("Following", followingCount),
                              ],
                            ),

                            const SizedBox(height: 18),

                            /// ACTIONS
                            if (!isOwner)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  StreamBuilder<bool>(
                                    stream: FollowService.isFollowing(
                                      widget.userId,
                                    ),
                                    builder: (_, snap) {
                                      final isFollowing = snap.data ?? false;

                                      return ElevatedButton(
                                        onPressed: () {
                                          FollowService.toggleFollow(
                                            widget.userId,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFollowing
                                              ? Colors.grey
                                              : AppTheme.primary,
                                          foregroundColor: Colors.black,
                                        ),
                                        child: Text(
                                          isFollowing ? "Following" : "Follow",
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.chat),
                                    label: const Text("Message"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () async {
                                      final convId =
                                          await PrivateChatService.getOrCreateConversation(
                                            widget.userId,
                                          );

                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            conversationId: convId,
                                            otherUserId: widget.userId,
                                            otherUserName: name,
                                            otherUserPhoto: imageUrl ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            else
                              const Text(
                                "Tap image to update your photo",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),


/// ✅ ✅ ✅ REELS GRID (FINAL CLEAN VERSION)
SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 2),
  sliver: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('reels')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final reels = snapshot.data!.docs;

      if (reels.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                "No reels yet",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        );
      }

      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data =
                reels[index].data() as Map<String, dynamic>;

            // ✅ ✅ SAFE IMAGE URL (NO CRASHES)
            final imageUrl =
                (data['thumbnailUrl'] ??
                        data['mediaUrl'] ??
                        '')
                    .toString();

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReelsPage(
                      isVisible: true,
                      initialReelId: reels[index].id,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(1),
                color: Colors.black,

                child: imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,

                        // ✅ LOADING INDICATOR
                        loadingBuilder:
                            (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white38,
                            ),
                          );
                        },

                        // ✅ ERROR HANDLER
                        errorBuilder: (context, error, stack) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                            ),
                          );
                        },
                      ),
              ),
            );
          },

          // ✅ MUST BE OUTSIDE BUILDER
          childCount: reels.length,
        ),

        // ✅ GRID STYLE
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
      );
    },
  ),
),



                  /// ✅ TABS (POSTS | REELS)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ✅ POSTS TAB
                          GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Posts",
                                style: TextStyle(
                                  color: _selectedTab == 0
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // ✅ REELS TAB
                          GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Reels",
                                style: TextStyle(
                                  color: _selectedTab == 1
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_selectedTab == 0) ...[
                    /// ✅ POSTS TITLE
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 10, 18, 6),
                        child: Text(
                          "Posts",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    /// ✅ POSTS LIST (CLEAN)
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('community_posts')
                          .where('authorId', isEqualTo: widget.userId)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (_, snap) {
                        if (!snap.hasData) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        final docs = snap.data!.docs;

                        if (docs.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  "No posts yet",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final doc = docs[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: PostCard(
                                key: ValueKey(doc.id),
                                postId: doc.id,
                              ),
                            );
                          }, childCount: docs.length),
                        );
                      },
                    ),
                  ],

                  if (_selectedTab == 1) ...[
                    /// ✅ ✅ REELS TITLE (NEW)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
                        child: Text(
                          "Reels",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    /// ✅ ✅ REELS GRID (NEW)
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('reels')
                          .where('userId', isEqualTo: widget.userId)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        final docs = snap.data!.docs;

                        if (docs.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  "No reels yet",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final data = docs[index].data();

                              final mediaUrl =
                                  (data['mediaUrl'] ?? data['videoUrl']) ?? '';

                              final isVideo = mediaUrl.toLowerCase().endsWith(
                                ".mp4",
                              );

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReelsPage(
                                        isVisible: true,
                                        userId: widget.userId,
                                        startIndex: index,
                                      ),
                                    ),
                                  );
                                },

                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    borderRadius: BorderRadius.circular(12),
                                    image: (mediaUrl.isNotEmpty && !isVideo)
                                        ? DecorationImage(
                                            image: NetworkImage(mediaUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),

                                  child: Stack(
                                    children: [
                                      // ✅ ✅ REAL VIDEO THUMBNAIL
                                      if (isVideo)
                                        Positioned.fill(
                                          child: FutureBuilder<VideoPlayerController>(
                                            future: _getController(mediaUrl),
                                            builder: (context, snap) {
                                              if (snap.connectionState ==
                                                      ConnectionState.done &&
                                                  snap.hasData) {
                                                final controller = snap.data!;

                                                // ✅ SAFE autoplay (won’t spam play calls)
                                                if (!controller
                                                    .value
                                                    .isPlaying) {
                                                  controller.play();
                                                }

                                                return ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: FittedBox(
                                                    fit: BoxFit.cover,
                                                    child: SizedBox(
                                                      width: controller
                                                          .value
                                                          .size
                                                          .width,
                                                      height: controller
                                                          .value
                                                          .size
                                                          .height,
                                                      child: VideoPlayer(
                                                        controller,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }

                                              // ✅ FALLBACK → still show thumbnail while loading
                                              return FutureBuilder<Uint8List?>(
                                                future: _getThumbnail(mediaUrl),
                                                builder: (context, snap) {
                                                  if (snap.hasData &&
                                                      snap.data != null) {
                                                    return ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: Image.memory(
                                                        snap.data!,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    );
                                                  }

                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      color: Colors.black,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                      // ✅ PLAY ICON CENTER
                                      if (isVideo)
                                        const Center(
                                          child: Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.white70,
                                            size: 34,
                                          ),
                                        ),

                                      // ✅ SMALL ICON (BOTTOM RIGHT)
                                      if (isVideo)
                                        const Positioned(
                                          right: 6,
                                          bottom: 6,
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: Colors.white54,
                                            size: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }, childCount: docs.length),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                          ),
                        );
                      },
                    ),
                  ],

                  /// ✅ END SPACING
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

Widget _countItem(String label, int count) {
  return GestureDetector(
    onTap: () {
      if (label == "Followers") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FollowersPage(userId: widget.userId),
          ),
        );
      } else if (label == "Following") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FollowingPage(userId: widget.userId),
          ),
        );
      }
    },
    child: Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    ),
  );
}
}
