import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final Timestamp timestamp;

  final int likeCount;
  final int commentCount;

  final List<Comment> comments;
  final String visibility;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.timestamp,
    required this.likeCount,
    required this.commentCount,
    required this.comments,
    this.visibility = 'public',
  });

  // ✅ ✅ FIX: Compatibility getters for UI
  List<String> get likes => List.filled(likeCount, "like");
  List<Comment> get commentList => comments;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final commentsData =
        (data['comments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Comment.fromMap)
            .toList() ??
        <Comment>[];

    final resolvedMediaUrl = (data['mediaUrl'] ?? data['imageUrl']) as String?;

    return Post(
      id: doc.id,
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? '').toString(),
      authorPhoto: data['authorPhoto'] as String?,
      content: (data['content'] ?? '').toString(),
      mediaUrl: resolvedMediaUrl,
      mediaType: data['mediaType'] as String?,
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp']
          : Timestamp.now(),

      likeCount: data['likeCount'] is int
          ? data['likeCount']
          : (data['likes'] is List ? (data['likes'] as List).length : 0),

      commentCount: data['commentCount'] is int
          ? data['commentCount']
          : commentsData.length,

      comments: commentsData,
      visibility: (data['visibility'] ?? 'public').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': timestamp,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'visibility': visibility,
    };
  }
}

class Comment {
  final String userId;
  final String userName;
  final String? userPhoto;
  final String text;
  final Timestamp timestamp;

  Comment({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
      userPhoto: map['userPhoto'] as String?,
      text: (map['comment'] ?? map['text'] ?? '').toString(),
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp']
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'comment': text,
      'timestamp': timestamp,
    };
  }
}
