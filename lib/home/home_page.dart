// lib/home/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Service & Model Imports
import '../services/post_service.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/titan_shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  static const Color accentYellow = Color(0xFFFFCC00);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("Identity Verification Required", style: TextStyle(color: Colors.white38))),
      );
    }

    final List<Widget> pages = [
      const _FeedTab(),
      const _ExploreTab(),
      const _ReelsTab(),
      const _MessagesTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0e1a2b), Color(0xFF050505)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(context, user),
            drawer: const AppDrawer(),
            body: IndexedStack(index: _currentIndex, children: pages),
            bottomNavigationBar: _buildBottomNav(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, User user) {
    return AppBar(
      title: Image.asset('assets/sda_logo.png', height: 40),
      backgroundColor: Colors.teal,
      centerTitle: true,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: accentYellow),
          onPressed: () => context.push('/search'),
        ),
        _buildNotificationBadge(user.uid),
        IconButton(
          icon: const Icon(Icons.settings, color: accentYellow),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildNotificationBadge(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').where('read', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: accentYellow),
              onPressed: () => context.push('/notifications'),
            ),
            if (count > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        FirebaseAnalytics.instance.logEvent(name: "nav_tab_switch", parameters: {"index": index});
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), activeIcon: Icon(Icons.play_circle_fill), label: 'Reels'),
        BottomNavigationBarItem(icon: Icon(Icons.message_outlined), activeIcon: Icon(Icons.message), label: 'Inbox'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Identity'),
      ],
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildPulseDock(context)),
            SliverToBoxAdapter(child: _buildLiveComposer(context)),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: PostService.postsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ShimmerPost(),
                      childCount: 3,
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const SliverFillRemaining(child: Center(child: Text("Mission field is quiet...", style: TextStyle(color: Colors.white24))));
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostCard(post: Post.fromDoc(docs[index])),
                    childCount: docs.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseDock(BuildContext context) {
    final tools = [
      {'label': 'BIBLE', 'icon': Icons.auto_stories_outlined, 'route': '/bible', 'color': const Color(0xFF00FFCC)},
      {'label': 'PRAYER', 'icon': Icons.volunteer_activism_outlined, 'route': '/prayer', 'color': const Color(0xFFFFCC00)},
      {'label': 'ACADEMY', 'icon': Icons.school_outlined, 'route': '/lessons', 'color': Colors.blueAccent},
      {'label': 'MANNA', 'icon': Icons.menu_book_outlined, 'route': '/devotionals', 'color': Colors.orangeAccent},
      {'label': 'NETWORK', 'icon': Icons.people_outline, 'route': '/friends', 'color': Colors.purpleAccent},
    ];
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final color = tools[i]['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => context.push(tools[i]['route'] as String),
              child: Column(children: [
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.2))), child: Icon(tools[i]['icon'] as IconData, color: color, size: 26)),
                const SizedBox(height: 8),
                Text(tools[i]['label'] as String, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveComposer(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final photo = snapshot.data?.data()?['photoURL'];
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
          child: InkWell(
            onTap: () => context.push('/create_post'),
            child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: const Color(0xFF008080), backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? const Icon(Icons.person, size: 18, color: Colors.white) : null),
              const SizedBox(width: 16),
              const Expanded(child: Text("What's on your heart?", style: TextStyle(color: Colors.white24, fontSize: 15, fontWeight: FontWeight.w500))),
              const Icon(Icons.add_a_photo_outlined, color: Color(0xFF00FFCC), size: 20),
            ]),
          ),
        );
      },
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: _ExploreComposer()),
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(24, 30, 24, 12), child: Text("DISCOVERY HUB", style: TextStyle(color: Color(0xFFFFCC00), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)))),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.4),
            delegate: SliverChildListDelegate([
              _discoveryCard(context, 'Devotionals', Icons.menu_book, Colors.blueAccent, '/devotionals'),
              _discoveryCard(context, 'Daily Bible', Icons.auto_stories, Colors.greenAccent, '/bible'),
              _discoveryCard(context, 'Events', Icons.event_available, Colors.orangeAccent, '/events'),
              _discoveryCard(context, 'Testimonies', Icons.auto_awesome, Colors.purpleAccent, '/testimonies'),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _discoveryCard(BuildContext context, String label, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 32), const SizedBox(height: 8), Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))]),
      ),
    );
  }
}

class _ExploreComposer extends StatefulWidget {
  const _ExploreComposer();
  @override State<_ExploreComposer> createState() => _ExploreComposerState();
}

class _ExploreComposerState extends State<_ExploreComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;
  Future<void> _handlePost() async {
    final text = _controller.text.trim(); if (text.isEmpty) return;
    setState(() => _isPosting = true);
    final ref = await PostService.createCommunityPost(content: text);
    if (mounted) { setState(() => _isPosting = false); if (ref != null) { _controller.clear(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shared to community feed!"))); } }
  }
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Column(children: [
        TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "What's on your heart?", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none)),
        const Divider(color: Colors.white10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Icon(Icons.image_outlined, color: Color(0xFF00FFCC), size: 20),
          ElevatedButton(onPressed: _isPosting ? null : _handlePost, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black), child: _isPosting ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text("POST")),
        ]),
      ]),
    );
  }
}

class _ReelsTab extends StatelessWidget {
  const _ReelsTab();
  @override Widget build(BuildContext context) {
    return Stack(children: [
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('media').where('mediaType', isEqualTo: 'video').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading reels.", style: TextStyle(color: Colors.white54)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          final raw = snapshot.data!.docs;
          if (raw.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("No mission reels yet", style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 10), ElevatedButton.icon(onPressed: () => context.push('/media'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.upload_rounded), label: const Text("Upload to Media Hub"))]));
          final docs = [...raw]..sort((a, b) {
            final ta = a.data()['timestamp']; final tb = b.data()['timestamp'];
            final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            final db = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
          return PageView.builder(scrollDirection: Axis.vertical, itemCount: docs.length, itemBuilder: (context, index) {
            final data = docs[index].data(); final url = (data['url'] ?? '').toString();
            final authorName = (data['authorName'] ?? 'Mission Member').toString();
            if (url.isEmpty) return const Center(child: Text("Invalid video URL.", style: TextStyle(color: Colors.white54)));
            return _ReelVideo(videoUrl: url, authorName: authorName);
          });
        },
      ),
      Positioned(right: 16, bottom: 16, child: FloatingActionButton.extended(heroTag: 'reels_upload_fab', backgroundColor: Colors.teal, icon: const Icon(Icons.upload_rounded, color: Colors.white), label: const Text("UPLOAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: () => context.push('/media'))),
    ]);
  }
}

class _ReelVideo extends StatefulWidget {
  final String videoUrl; final String authorName;
  const _ReelVideo({required this.videoUrl, required this.authorName});
  @override State<_ReelVideo> createState() => _ReelVideoState();
}

class _ReelVideoState extends State<_ReelVideo> {
  VideoPlayerController? _controller; bool _initialized = false;
  @override void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))..initialize().then((_) { if (!mounted) return; setState(() => _initialized = true); _controller!.setLooping(true); _controller!.play(); }).catchError((_) { if (!mounted) return; setState(() => _initialized = false); });
  }
  @override void dispose() { _controller?.dispose(); super.dispose(); }
  void _onVisibilityChanged(VisibilityInfo info) { if (_controller == null || !_initialized) return; if (info.visibleFraction > 0.6) { _controller!.play(); } else { _controller!.pause(); } }
  @override Widget build(BuildContext context) {
    return VisibilityDetector(key: ValueKey(widget.videoUrl), onVisibilityChanged: _onVisibilityChanged, child: Stack(fit: StackFit.expand, children: [Container(color: Colors.black), if (_controller != null && _initialized) FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controller!.value.size.width, height: _controller!.value.size.height, child: VideoPlayer(_controller!))) else const Center(child: CircularProgressIndicator(color: Colors.teal)), Positioned(left: 16, bottom: 40, right: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("@${widget.authorName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 8), const Text("Mission Reel", style: TextStyle(color: Colors.white70, fontSize: 13))])), Positioned(right: 16, bottom: 60, child: Column(children: const [Icon(Icons.favorite_border, color: Colors.white, size: 30), SizedBox(height: 20), Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30), SizedBox(height: 20), Icon(Icons.share, color: Colors.white, size: 30)]))]));
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  Future<Map<String, dynamic>> _getPeerMetadata(String? uid) async {
    if (uid == null) return {'name': 'Mission Member', 'photo': null};
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return {'name': doc.data()?['name'] ?? 'Mission Member', 'photo': doc.data()?['photoURL']};
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 16), child: Text("INBOX", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3))),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('conversations').where('participants', arrayContains: me?.uid).orderBy('lastUpdated', descending: true).snapshots(),
        builder: (context, snapshot) {
          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) return const Center(child: Text("Inbox Empty", style: TextStyle(color: Colors.white12)));
          return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: chats.length, itemBuilder: (context, i) {
            final data = chats[i].data();
            final participants = List<String>.from(data['participants'] ?? []);
            final peerUid = participants.firstWhere((id) => id != me?.uid, orElse: () => "");
            return FutureBuilder<Map<String, dynamic>>(
              future: _getPeerMetadata(peerUid),
              builder: (context, meta) {
                final name = meta.data?['name'] ?? "Loading...";
                final photo = meta.data?['photo'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                  child: ListTile(
                    leading: CircleAvatar(radius: 20, backgroundColor: Colors.white12, backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? const Icon(Icons.person, color: Colors.white24) : null),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(data['lastMessage'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    onTap: () => context.push('/messages/${data['recipientEmail'] ?? peerUid}'),
                  ),
                );
              },
            );
          });
        },
      )),
    ]);
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = data['name'] ?? "Mission Member";
        final photo = data['photoURL'];
        final email = data['email'] ?? "";
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(radius: 50, backgroundColor: Colors.white12, backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? const Icon(Icons.person, size: 40, color: Colors.white54) : null),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(email, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: () => context.push('/profile'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("EDIT PROFILE")),
        ]));
      },
    );
  }
}
