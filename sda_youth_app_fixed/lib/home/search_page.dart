import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearching = false;

  void _startSearch(String value) {
    setState(() {
      _query = value.trim();
      _isSearching = _query.isNotEmpty;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _searchStream() {
    if (_query.isEmpty) {
      return const Stream.empty();
    }
    // Simple text search: filter posts where body contains query
    return FirebaseFirestore.instance
        .collection('posts')
        .where('body', isGreaterThanOrEqualTo: _query)
        .where('body', isLessThanOrEqualTo: '$_query\uf8ff')
        .orderBy('body')
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Posts"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search posts...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _startSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !_isSearching || _query.isEmpty
                  ? const Center(child: Text("Type something to search"))
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _searchStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No results found."));
                        }
                        final results = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final data = results[index].data();
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.article,
                                  color: Colors.teal,
                                ),
                                title: Text(data['title'] ?? 'Post'),
                                subtitle: Text(
                                  data['body'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
