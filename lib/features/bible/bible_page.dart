// lib/features/bible/bible_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/services/bible_service.dart';

/// Bible Sector — World-class Immersive Scripture Engine for SDA Youth.
/// Manages high-performance reading, sacred markers, and cinematic navigation.
class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color premiumBlack = Color(0xFF050505);

  String _selectedTranslation = 'kjv';
  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;

  final List<String> _oldTestament = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth',
    '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
    'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi'
  ];

  final List<String> _newTestament = [
    'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians',
    'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter',
    '1 John', '2 John', '3 John', 'Jude', 'Revelation'
  ];

  void _showSelectorHub() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text("SELECT HOLY SCRIPTURE", style: TextStyle(color: accentYellow, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 13)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectorHeader("Old Testament"),
                    ..._oldTestament.map((b) => _buildBookTile(b)),
                    const SizedBox(height: 24),
                    _buildSectorHeader("New Testament"),
                    ..._newTestament.map((b) => _buildBookTile(b)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectorHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(title.toUpperCase(), style: const TextStyle(color: electricTeal, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
    );
  }

  Widget _buildBookTile(String bookName) {
    final isSelected = _selectedBook == bookName;
    return ListTile(
      onTap: () {
        setState(() { _selectedBook = bookName; _selectedChapter = 1; });
        Navigator.pop(context);
        FirebaseAnalytics.instance.logEvent(name: 'bible_book_selected', parameters: {'book': bookName});
      },
      title: Text(bookName, style: TextStyle(color: isSelected ? accentYellow : Colors.white70, fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold)),
      trailing: isSelected ? const Icon(Icons.check_circle_outline, color: accentYellow, size: 18) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: InkWell(
          onTap: _showSelectorHub,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$_selectedBook $_selectedChapter", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, color: electricTeal),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded, color: electricTeal),
            onPressed: () {
              setState(() => _selectedTranslation = _selectedTranslation == 'kjv' ? 'osh' : 'kjv');
              _showFeedback("Translation: ${_selectedTranslation.toUpperCase()}");
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Cinematic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // 2. Immersive Scripture Stream with Sacred Markers
                Expanded(child: _buildVerseStream()),

                // 3. Navigation Engine Dock
                _buildNavigationDock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bible')
          .doc(_selectedTranslation)
          .collection('books')
          .doc(_selectedBook)
          .collection('chapters')
          .doc(_selectedChapter.toString())
          .collection('verses')
          .orderBy('verseNumber')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: electricTeal));
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: BibleService.getMarkersStream(_selectedBook, _selectedChapter),
          builder: (context, markerSnap) {
            // Map markers for 0ms lookup during build
            final markedVerses = markerSnap.data?.docs.map((m) => m.data()['verse'] as int).toSet() ?? {};

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final verseNum = data['verseNumber'] as int;
                final isMarked = markedVerses.contains(verseNum);

                return GestureDetector(
                  onLongPress: () {
                    BibleService.toggleSacredMarker(
                      bookName: _selectedBook, 
                      chapter: _selectedChapter, 
                      verse: verseNum, 
                      text: data['text'].toString()
                    );
                    _showFeedback(isMarked ? "Marker Removed" : "Sacred Marker Set");
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 19, 
                          height: 1.7, 
                          fontFamily: 'NotoSans',
                          backgroundColor: isMarked ? accentYellow.withValues(alpha: 0.15) : null,
                        ),
                        children: [
                          TextSpan(
                            text: "$verseNum  ", 
                            style: TextStyle(
                              color: isMarked ? accentYellow : electricTeal, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 13
                            ),
                          ),
                          TextSpan(
                            text: data['text'].toString(),
                            style: TextStyle(
                              color: isMarked ? accentYellow : Colors.white, 
                              fontWeight: isMarked ? FontWeight.bold : FontWeight.w400
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
        );
      },
    );
  }

  Widget _buildNavigationDock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navAction("PREVIOUS", Icons.arrow_back_ios_new, () {
            if (_selectedChapter > 1) setState(() => _selectedChapter--);
          }),
          _navAction("NEXT", Icons.arrow_forward_ios, () {
            setState(() => _selectedChapter++);
          }, isTrailing: true),
        ],
      ),
    );
  }

  Widget _navAction(String label, IconData icon, VoidCallback onTap, {bool isTrailing = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          if (!isTrailing) Icon(icon, color: electricTeal, size: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
          if (isTrailing) Icon(icon, color: electricTeal, size: 14),
        ],
      ),
    );
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: accentYellow,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, color: Colors.white.withValues(alpha: 0.05), size: 100),
          const SizedBox(height: 20),
          const Text("ACCESSING SCRIPTURE...", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }
}
