import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  String _selectedTranslation = 'kjv';
  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;

  final List<String> _books = [
    'Genesis',
    'Exodus',
    'Leviticus',
    'Numbers',
    'Deuteronomy',
    // TODO: add all 66 books here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bible"), backgroundColor: Colors.teal),
      body: SafeArea(
        child: Column(
          children: [
            // Translation selector
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedTranslation,
                items: const [
                  DropdownMenuItem(
                    value: 'kjv',
                    child: Text('King James (English)'),
                  ),
                  DropdownMenuItem(value: 'osh', child: Text('Oshiwambo')),
                  DropdownMenuItem(value: 'afr', child: Text('Afrikaans')),
                  DropdownMenuItem(value: 'otj', child: Text('Otjiherero')),
                ],
                onChanged: (val) => setState(() => _selectedTranslation = val!),
                decoration: const InputDecoration(
                  labelText: "Translation",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),

            // Book selector
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedBook,
                items: _books
                    .map((book) => DropdownMenuItem(value: book, child: Text(book)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBook = val!),
                decoration: const InputDecoration(
                  labelText: "Book",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),

            // Chapter selector
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Text("Chapter: "),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_selectedChapter > 1) {
                        setState(() => _selectedChapter--);
                      }
                    },
                  ),
                  Text("$_selectedChapter"),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _selectedChapter++),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Verses
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No verses found."));
                  }

                  final verses = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final verse = verses[index].data();
                      return ListTile(
                        title: Text(
                          "${verse['verseNumber']}. ${verse['text']}",
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
