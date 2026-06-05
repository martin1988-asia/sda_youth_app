// ✅ FULL ELITE REELS SYSTEM — COMPLETE (NO FEATURES REMOVED)

import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'upload_reel_page.dart';

import '../messages/share_reel_page.dart';
import '../../core/route_observer.dart';
import '../profile/profile_view_page.dart';

class ReelsPage extends StatefulWidget {
  final bool isVisible;

  // ✅ NEW (for profile integration)
  final String? userId;
  final int startIndex;

  final String? initialReelId;

  const ReelsPage({
    super.key,
    required this.isVisible,
    this.userId,
    this.startIndex = 0,
    this.initialReelId,
  });

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _controller = PageController(viewportFraction: 1.0);
  int _currentIndex = 0;

  bool _showFollowing = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _reels = [];
  DocumentSnapshot? _last;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
    );

    _loadInitial();

    // ✅ START AT SELECTED REEL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startIndex > 0) {
        _controller.jumpToPage(widget.startIndex);
      }
    });
  }

  // ✅ FINAL AI FEED ENGINE (PRODUCTION GRADE 🔥)
  Future<void> _loadInitial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final filterUserId = widget.userId;

    QuerySnapshot<Map<String, dynamic>> snap;

    if (_showFollowing) {
      // ✅ FOLLOWING FEED
      final followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      final ids = followingSnap.docs.map((e) => e.id).toList();

      if (ids.isEmpty) {
        snap = await FirebaseFirestore.instance
            .collection('reels')
            .limit(10)
            .get();
      } else {
        snap = await FirebaseFirestore.instance
            .collection('reels')
            .where('userId', whereIn: ids.take(10).toList())
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
      }

      if (snap.docs.isNotEmpty) {
        _last = snap.docs.last;
        _reels = snap.docs;
      }
    } else {
      // ✅ FOR YOU (AI PERSONALIZATION)

      // 🔹 USER INTERESTS
      final interestsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('interests')
          .get();

      Map<String, int> prefs = {};
      for (var doc in interestsSnap.docs) {
        final value = doc.data()['watchTime'];
        prefs[doc.id] = (value is num) ? value.toInt() : 0;
      }

      // ✅ GET FOLLOWING USERS (NEW)
      final followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      final followingIds = followingSnap.docs.map((e) => e.id).toSet();

      // 🔹 LOAD REELS
      Query query = FirebaseFirestore.instance
          .collection('reels')
          .orderBy('timestamp', descending: true);

      // ✅ APPLY USER FILTER IF PRESENT
      if (filterUserId != null) {
        query = query.where('userId', isEqualTo: filterUserId);
      }

      final reelsSnap = await query.limit(30).get();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> reels = reelsSnap
          .docs
          .cast<QueryDocumentSnapshot<Map<String, dynamic>>>();

      final now = DateTime.now().millisecondsSinceEpoch;

      // 🔹 ADVANCED SORTING ENGINE 🔥
      reels.sort((a, b) {
        final da = a.data();
        final db = b.data();

        int scoreA = (da['score'] is num) ? da['score'].toInt() : 0;
        int scoreB = (db['score'] is num) ? db['score'].toInt() : 0;

        int watchA = (da['totalWatchTime'] is num)
            ? da['totalWatchTime'].toInt()
            : 0;
        int watchB = (db['totalWatchTime'] is num)
            ? db['totalWatchTime'].toInt()
            : 0;

        int skipA = (da['skipCount'] is num) ? da['skipCount'].toInt() : 0;
        int skipB = (db['skipCount'] is num) ? db['skipCount'].toInt() : 0;

        int prefA = prefs['cat_${da['category']}'] ?? 0;
        int prefB = prefs['cat_${db['category']}'] ?? 0;

        int normPrefA = (prefA / 1000).round();
        int normPrefB = (prefB / 1000).round();

        int ageA =
            now -
            ((da['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? now);

        int ageB =
            now -
            ((db['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? now);

        int freshnessA = (ageA ~/ 60000).clamp(0, 10000);
        int freshnessB = (ageB ~/ 60000).clamp(0, 10000);

        // 👥 FOLLOW BOOST (NEW)
        bool followsA = followingIds.contains(da['userId']);
        bool followsB = followingIds.contains(db['userId']);

        int followBoostA = followsA ? 120 : 0;
        int followBoostB = followsB ? 120 : 0;

        // 🚀 VIRAL BOOST (NEW)
        int viralA = ((da['reactionsCount'] ?? 0) > 50) ? 150 : 0;

        int viralB = ((db['reactionsCount'] ?? 0) > 50) ? 150 : 0;

        // ✝️ FAITH BOOST (NEW)
        bool isFaithA =
            (da['caption'] ?? "").toString().toLowerCase().contains('jesus') ||
            (da['caption'] ?? "").toString().toLowerCase().contains('god');

        bool isFaithB =
            (db['caption'] ?? "").toString().toLowerCase().contains('jesus') ||
            (db['caption'] ?? "").toString().toLowerCase().contains('god');

        int faithBoostA = isFaithA ? 100 : 0;
        int faithBoostB = isFaithB ? 100 : 0;

        // ✅ FINAL SCORE (BALANCED)

        int finalA =
            scoreA +
            (watchA ~/ 1000) +
            normPrefA -
            (skipA * 5) -
            freshnessA +
            faithBoostA +
            followBoostA +
            viralA;

        int finalB =
            scoreB +
            (watchB ~/ 1000) +
            normPrefB -
            (skipB * 5) -
            freshnessB +
            faithBoostB +
            followBoostB +
            viralB;

        return finalB.compareTo(finalA);
      });

      // ✅ SMART DIVERSITY (BALANCED + NON-RANDOM 🔥)
      final top = reels.take(12).toList(); // keep strongest
      final mid = reels.skip(12).take(8).toList()..shuffle(); // mix variety
      final rest = reels.skip(20).toList()..shuffle(); // background pool

      // ✅ FINAL FEED (ORDERED + DIVERSE)
      final finalFeed = [...top, ...mid.take(4), ...rest.take(2)];

      // 🚫 LIMIT SAME CATEGORY (NEW)
      Map<String, int> categoryCount = {};
      List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered = [];

      for (var reel in finalFeed) {
        final cat = reel.data()['category'] ?? 'general';

        if ((categoryCount[cat] ?? 0) < 3) {
          filtered.add(reel);
          categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
        }
      }

      _reels = filtered.take(12).toList();

      _last = _reels.isNotEmpty ? _reels.last : null;
    }


    // ✅ SCROLL TO SPECIFIC REEL (NEW)
    if (widget.initialReelId != null) {
      final index =
          _reels.indexWhere((r) => r.id == widget.initialReelId);

      if (index != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.jumpToPage(index);
        });
      }
    }


    if (mounted) setState(() {});
  }

  Future<void> _loadMore() async {
    if (_last == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('reels')
        .orderBy('score', descending: true)
        .startAfterDocument(_last!)
        .limit(5)
        .get();

    if (snap.docs.isNotEmpty) {
      _last = snap.docs.last;
      _reels.addAll(snap.docs);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No reels available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,

      // ✅ ✅ TIKTOK-STYLE CENTERED FAB (NO COLLISION 🚀)

      // ✅ ✅ TIKTOK-STYLE CENTERED FAB (NO COLLISION 🚀)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.black),

          // ✅ ADVANCED CREATOR FLOW (FINAL CLEAN VERSION)
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) {
                final picker = ImagePicker();

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ CAMERA
                        ListTile(
                          leading: const Icon(
                            Icons.videocam,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "Record Video",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            Navigator.pop(context);

                            final picked = await picker.pickVideo(
                              source: ImageSource.camera,
                            );

                            if (picked == null) return;
                            if (!mounted) return;

                            // ✅ FIX: declare BEFORE widget
                            final isVideo =
                                picked.mimeType?.startsWith("video") ?? false;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UploadReelPage(
                                  videoFile: isVideo ? picked : null,
                                  imageFile: !isVideo ? picked : null,
                                ),
                              ),
                            );
                          },
                        ),

                        // ✅ GALLERY
                        ListTile(
                          leading: const Icon(
                            Icons.perm_media,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "Photo or Video",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            Navigator.pop(context);

                            final picked = await picker.pickMedia();
                               
                            if (picked == null) return;

                            // ✅ CAPTURE BEFORE ASYNC GAP

                            if (!mounted) return;

                            final isVideo =
                                picked.mimeType?.startsWith("video") ?? false;

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UploadReelPage(
                                  videoFile: isVideo ? picked : null,
                                  imageFile: isVideo ? null : picked,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      body: Stack(
        children: [
          // ✅ PAGEVIEW
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                final velocity = notification.dragDetails?.primaryVelocity ?? 0;

                if (velocity.abs() > 2000) {
                  final target = velocity < 0
                      ? _currentIndex + 1
                      : _currentIndex - 1;

                  if (target >= 0 && target < _reels.length) {
                    _controller.animateToPage(
                      target,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                }
              }
              return false;
            },

            child: PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _reels.length,

              onPageChanged: (i) {
                if (_currentIndex == i) return;

                HapticFeedback.lightImpact();

                setState(() {
                  _currentIndex = i;
                });

                if (i >= _reels.length - 3) {
                  _loadMore();
                }
              },

              itemBuilder: (_, i) {
                if (i >= _reels.length) {
                  return const SizedBox();
                }

                final data = _reels[i].data();

                final nextData = (i + 1 < _reels.length)
                    ? _reels[i + 1].data()
                    : null;

                return ReelItem(
                  reelId: _reels[i].id,
                  userId: data['userId'] ?? '',
                  videoUrl: (data['mediaUrl'] ?? data['videoUrl']) ?? '',
                  type: data['type'] ?? 'video',
                  username: data['userName'] ?? 'User',
                  userPhotoUrl: data['userPhotoUrl'],
                  caption: data['caption'] ?? '',
                  category: data['category'] ?? 'general',
                  isActive: i == _currentIndex && widget.isVisible,
                  likesCount: data['reactionsCount'] ?? 0,
                  commentsCount: data['commentsCount'] ?? 0,

                  // ✅ FIXED SAFE VERSION
                  preloadUrl: nextData?['videoUrl'],
                );
              },
            ),
          ),

          // ✅ TOP TABS
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _showFollowing = true);
                        _loadInitial();
                      },
                      child: Text(
                        "Following",
                        style: TextStyle(
                          color: _showFollowing ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showFollowing = false);
                        _loadInitial();
                      },
                      child: Text(
                        "For You",
                        style: TextStyle(
                          color: !_showFollowing
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ SINGLE GRADIENT (FIXED)
          IgnorePointer(
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ REEL ITEM (FULL SYSTEM)

class ReelItem extends StatefulWidget {
  final String reelId, videoUrl, username, userId, caption, category, type;
  final bool isActive;
  final String? preloadUrl;
  final int likesCount;
  final int commentsCount;
  final String? userPhotoUrl;

  const ReelItem({
    super.key,
    required this.reelId,
    required this.videoUrl,
    required this.username,
    required this.userId,
    required this.caption,
    required this.category,
    required this.isActive,
    required this.type,
    required this.likesCount,
    required this.commentsCount,
    this.preloadUrl,
    this.userPhotoUrl,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem>
    with WidgetsBindingObserver, RouteAware {
  late VideoPlayerController _video;
  VideoPlayerController? _next;

  bool _ready = false;
  int _start = 0;
  bool _paused = false;
  bool _muted = false;
  bool _tracked = false;

  bool _showHeart = false;
  double _heartScale = 0.8;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _checkFollowing();

    if (kIsWeb) {
      // ✅ WEB → use network video
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (!mounted) return;

          setState(() => _ready = true);
          _video.seekTo(Duration.zero);

          if (widget.isActive) {
            _video.play();
            _start = DateTime.now().millisecondsSinceEpoch;
          }
        })
        ..setLooping(true)
        ..setVolume(1.0);

      _muted = false;
    } else {
      // ✅ MOBILE → use cached file
      DefaultCacheManager().getSingleFile(widget.videoUrl).then((file) {
        _video = VideoPlayerController.file(file)
          ..initialize().then((_) {
            if (!mounted) return;

            setState(() => _ready = true);
            _video.seekTo(Duration.zero);

            // ✅ START PLAYING FIRST TIME
            if (widget.isActive) {
              _video.play();
              _start = DateTime.now().millisecondsSinceEpoch;
            }

            // ✅ WARM UP NEXT VIDEO
            if (_next != null) {
              _next!.initialize();
            }
          })
          ..setLooping(true)
          ..setVolume(1.0);

        _muted = false;
      });
    }

    // ✅ PRELOAD NEXT VIDEO (CACHED ✅🔥)
    if (widget.preloadUrl != null && widget.preloadUrl!.isNotEmpty) {
      if (kIsWeb) {
        // ✅ WEB → use network
        _next = VideoPlayerController.networkUrl(Uri.parse(widget.preloadUrl!))
          ..initialize().then((_) {
            _next!.setVolume(0);
          });
      } else {
        // ✅ MOBILE → use cached file
        DefaultCacheManager().getSingleFile(widget.preloadUrl!).then((file) {
          _next = VideoPlayerController.file(file)
            ..initialize().then((_) {
              _next!.setVolume(0);
            });
        });
      }
    }
  }

  @override
  void deactivate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_video.value.isPlaying) {
        _video.pause(); // ✅ STOP video when switching tabs
      }
    });
      super.deactivate();
   }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // ✅ ✅ ✅ ADD THIS METHOD HERE
  Future<void> _checkFollowing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(widget.userId)
        .get();

    if (!mounted) return;
    setState(() {
      _isFollowing = doc.exists;
    });
  }

// ✅ ✅ ✅ ADD THIS RIGHT AFTER
Future<void> _toggleFollow() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final myId = user.uid;
  final targetId = widget.userId;

  final followingRef = FirebaseFirestore.instance
      .collection('users')
      .doc(myId)
      .collection('following')
      .doc(targetId);

  final followersRef = FirebaseFirestore.instance
      .collection('users')
      .doc(targetId)
      .collection('followers')
      .doc(myId);

  try {
    if (_isFollowing) {
      // ✅ UNFOLLOW
      await followingRef.delete();
      await followersRef.delete();

      // ✅ DECREASE COUNTS
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myId)
          .update({
        'followingCount': FieldValue.increment(-1),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .update({
        'followersCount': FieldValue.increment(-1),
      });

    } else {
      // ✅ FOLLOW
      await followingRef.set({
        'followedAt': FieldValue.serverTimestamp(),
      });

      await followersRef.set({
        'followedAt': FieldValue.serverTimestamp(),
      });

      // ✅ INCREASE COUNTS
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myId)
          .update({
        'followingCount': FieldValue.increment(1),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .update({
        'followersCount': FieldValue.increment(1),
      });
    }

    if (!mounted) return;



      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      debugPrint("FOLLOW ERROR: $e");
    }
  }



  @override
  void didPopNext() {
    // ✅ User returned to Reels
    if (widget.isActive && !_paused && _video.value.isInitialized) {
      _video.play();
      _start = DateTime.now().millisecondsSinceEpoch;
    }
  }

  // ✅ ✅ ✅ ADD THIS HERE (RIGHT AFTER _toggleFollow)
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";

    return "${date.day}/${date.month}";
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive) {
      if (_video.value.isInitialized && !_video.value.isPlaying) {
        _video.play();

        if (_video.value.position == Duration.zero) {
          _start = DateTime.now().millisecondsSinceEpoch;
        }
      }
    } else {
      if (_video.value.isPlaying) {
        _track();
        _video.pause();
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    WidgetsBinding.instance.removeObserver(this);

    if (_video.value.isInitialized && _video.value.isPlaying) {
      _video.pause();
    }

    _track();

    _video.dispose();
    _next?.dispose();

    super.dispose();
  }

  // ================= PLAY =================
  void _togglePlay() {
    if (!_ready) return;

    setState(() => _paused = !_video.value.isPlaying);

    _video.value.isPlaying ? _video.pause() : _video.play();
  }

  // ✅ ADD THIS RIGHT BELOW 👇
  void _toggleMute() {
    if (!_ready) return;

    setState(() {
      _muted = !_muted;
    });

    _video.setVolume(_muted ? 0.0 : 1.0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _video.pause();
    }
  }

  // ✅ AI TRACKING + SCORING
  Future<void> _track() async {
    if (!mounted) return;
    if (_start == 0 || _tracked) return;
    _tracked = true;

    final duration = DateTime.now().millisecondsSinceEpoch - _start;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('interests')
          .doc(widget.reelId)
          .set({
            'watchTime': FieldValue.increment(duration),
          }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('interests')
          .doc("cat_${widget.category}")
          .set({
            'watchTime': FieldValue.increment(duration),
          }, SetOptions(merge: true));

      if (_video.value.isInitialized &&
          _video.value.duration.inMilliseconds > 0) {
        final percent =
            (_video.value.position.inMilliseconds /
                    _video.value.duration.inMilliseconds)
                .clamp(0.0, 1.0);

        await FirebaseFirestore.instance
            .collection('reels')
            .doc(widget.reelId)
            .collection('heatmap')
            .add({'percent': percent * 100});
      }

      int scoreBoost = (duration / 100).round();
      int skipPenalty = duration < 2000 ? 10 : 0;

      await FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reelId)
          .update({
            'totalWatchTime': FieldValue.increment(duration),
            if (duration < 2000) 'skipCount': FieldValue.increment(1),
            'score': FieldValue.increment(scoreBoost - skipPenalty),
          });
    } catch (e) {
      debugPrint("TRACK ERROR: $e");
    }

    _start = 0;
  }

  // ✅ LIKE SYSTEM
  Future<void> _like() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reelId)
          .collection('reactions')
          .doc(uid)
          .set({'type': 'love'});

      await FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reelId)
          .update({
            'reactionsCount': FieldValue.increment(1),
            'score': FieldValue.increment(50),
          });
    } catch (_) {}

    setState(() {
      _showHeart = true;
      _heartScale = 1.3;
    });

    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _heartScale = 1.0);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showHeart = false);
  }

void _share() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ OPTION 1: SEND IN CHAT
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.white),
              title: const Text(
                "Send in chat",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShareReelPage(
                      reelId: widget.reelId,
                    ),
                  ),
                );
              },
            ),

            // ✅ OPTION 2: SHARE OUTSIDE APP
            ListTile(
              leading: const Icon(Icons.public, color: Colors.white),
              title: const Text(
                "Share to WhatsApp / others",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);

                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      text:
                          "Watch this reel:\nhttps://yourapp.com/reel/${widget.reelId}",
                    ),
                  );
                } catch (e) {
                  debugPrint("SHARE ERROR: $e");
                }
              },
            ),
          ],
        ),
      );
    },
  );
}


void _showOptions() {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final isOwner = currentUser.uid == widget.userId;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete Reel",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        backgroundColor: Colors.black,
                        title: const Text(
                          "Delete Reel?",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          "This action cannot be undone.",
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await _deleteReel();
                  }
                },
              ),

            const ListTile(
              title: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _deleteReel() async {
  try {
    await FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reelId)
        .delete();

    if (!mounted) return;

    // ✅ SAFE POP (FIX)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reel deleted ✅")),
    );
  } catch (e) {
    debugPrint("DELETE ERROR: $e");
  }
}



  @override
  Widget build(BuildContext context) {
    final isVideo =
        widget.videoUrl.startsWith("blob:") ||
        widget.videoUrl.toLowerCase().endsWith(".mp4");

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.videoUrl.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : !isVideo
            // ✅ IMAGE ONLY
            ? Image.network(
                widget.videoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            // ✅ VIDEO ONLY
            : (_ready && _video.value.isInitialized)
            ? Transform.scale(
                scale: widget.isActive ? 1.0 : 0.98,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _togglePlay();
                  },
                  onDoubleTap: _like,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _video.value.size.width,
                        height: _video.value.size.height,
                        child: AnimatedOpacity(
                          opacity: _ready ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_video),

                                if (_video.value.isBuffering)
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

        // ✅ GRADIENT OVERLAY
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // ✅ TEXT (UNCHANGED)
        IgnorePointer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    "@${widget.username}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.caption,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ LIKE / COMMENT (FIXED)
        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            children: [

              // ✅ MORE OPTIONS (DELETE)
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  _showOptions();
                },
              ),

              // ✅ PROFILE AVATAR + FOLLOW BUTTON (FULL FIX 🔥)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileViewPage(userId: widget.userId),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[800],
                  backgroundImage:
                      (widget.userPhotoUrl != null &&
                          widget.userPhotoUrl!.isNotEmpty)
                      ? NetworkImage(widget.userPhotoUrl!)
                      : null,
                  child:
                      (widget.userPhotoUrl == null ||
                          widget.userPhotoUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),

              const SizedBox(height: 8),

              // ✅ FOLLOW BUTTON ✅ (THIS WAS MISSING)
              GestureDetector(
                onTap: _toggleFollow,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isFollowing ? Colors.grey : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isFollowing ? "Following" : "Follow",
                    style: TextStyle(
                      color: _isFollowing ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ LIKE
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: _like,
                  ),
                  Text(
                    _formatCount(widget.likesCount),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ COMMENTS
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.comment,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => CommentsSheet(reelId: widget.reelId),
                    ),
                  ),
                  Text(
                    _formatCount(widget.commentsCount),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ SHARE BUTTON (NEW 🔥)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 30),
                    onPressed: _share,
                  ),
                  const Text(
                    "Share",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ✅ PROGRESS BAR (NEW)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: (_video.value.isInitialized)
                ? VideoProgressIndicator(
                    _video,
                    allowScrubbing: false,
                    colors: VideoProgressColors(
                      playedColor: Colors.white,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white38,
                    ),
                  )
                : const SizedBox(),
          ),
        ),

        // ✅ MUTE ICON
        Positioned(
          left: 12,
          bottom: 60,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                _muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),

        // ✅ PLAY / PAUSE INDICATOR
        if (_paused)
          Center(
            child: AnimatedOpacity(
              opacity: _paused ? 1 : 0,
              duration: Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: Icon(Icons.play_arrow, size: 70, color: Colors.white),
              ),
            ),
          ),

        // ✅ HEART (keep this last)
        if (_showHeart)
          Center(
            child: AnimatedScale(
              scale: _heartScale,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.favorite, color: Colors.white, size: 110),
            ),
          ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return "${(count / 1000000).toStringAsFixed(1)}M";
    } else if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}K";
    }
    return count.toString();
  }
}

// ✅ REACTIONS
class ReactionBar extends StatelessWidget {
  final String reelId;

  const ReactionBar({super.key, required this.reelId});

  Future<void> _react(String type) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('reels')
        .doc(reelId)
        .collection('reactions')
        .doc(uid)
        .set({'type': type});

    await FirebaseFirestore.instance.collection('reels').doc(reelId).update({
      'reactionsCount': FieldValue.increment(1),
    });
  }

  Widget _btn(String emoji, String type) {
    return GestureDetector(
      onTap: () => _react(type),
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_btn("❤️", "love"), _btn("🔥", "fire"), _btn("🙏", "faith")],
    );
  }
}

// ✅ COMMENTS
class CommentsSheet extends StatefulWidget {
  final String reelId;

  const CommentsSheet({super.key, required this.reelId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController ctrl = TextEditingController();

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (ctrl.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reelId)
        .collection('comments')
        .add({
      'text': ctrl.text.trim(),
      'userId': user.uid,
      'userName': data['name'] ?? 'User',
      'userPhotoUrl': data['userPhotoUrl'] ?? '',
      'likesCount': 0, // ✅ NEW
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reelId)
        .update({'commentsCount': FieldValue.increment(1)});

    ctrl.clear();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";

    return "${date.day}/${date.month}";
  }

  Future<void> _toggleLike(
      String commentId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reelId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(uid);

    if (isLiked) {
      await ref.delete();
      await ref.parent.parent!.update({
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.set({'likedAt': FieldValue.serverTimestamp()});
      await ref.parent.parent!.update({
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Text(
              "Comments",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(color: Colors.white24),

            // ✅ COMMENT LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reels')
                    .doc(widget.reelId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!.docs;

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        "No comments yet",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final doc = comments[i];
                      final data = doc.data() as Map<String, dynamic>;

                      final timestamp = data['timestamp'] != null
                          ? (data['timestamp'] as Timestamp).toDate()
                          : null;

                      return GestureDetector(
                        onLongPress: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          if (data['userId'] != user.uid) return;

                          await doc.reference.delete();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage:
                                    (data['userPhotoUrl'] ?? '')
                                            .toString()
                                            .isNotEmpty
                                        ? NetworkImage(
                                            data['userPhotoUrl'])
                                        : null,
                                child: (data['userPhotoUrl'] == null ||
                                        data['userPhotoUrl'] ==
                                            '')
                                    ? const Icon(Icons.person,
                                        size: 14)
                                    : null,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          data['userName'] ??
                                              'User',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (timestamp != null)
                                          Text(
                                            _timeAgo(timestamp),
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Container(
                                      padding:
                                          const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                      ),
                                      child: Text(
                                        data['text'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            final uid =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid;

                                            final likeDoc =
                                                await doc
                                                    .reference
                                                    .collection(
                                                        'likes')
                                                    .doc(uid)
                                                    .get();

                                            final isLiked =
                                                likeDoc.exists;

                                            await _toggleLike(
                                                doc.id,
                                                isLiked);
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.favorite_border,
                                                color:
                                                    Colors.white70,
                                                size: 16,
                                              ),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                (data['likesCount'] ??
                                                        0)
                                                    .toString(),
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
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
                      );
                    },
                  );
                },
              ),
            ),

            // ✅ INPUT BAR (TIKTOK-STYLE ✅ FULL FIX)
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Colors.black,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Row(
                        children: [
                          // ✅ TEXT INPUT (NOT EDGE-TO-EDGE)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: ctrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Write a comment...",
                                  hintStyle:
                                      TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // ✅ SEND BUTTON
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: _send,
                              icon: const Icon(
                                Icons.send,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
