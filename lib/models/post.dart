// lib/models/post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Post model — aligned with /community_posts documents.
///
/// Firestore shape used by PostService:
///   community_posts/{postId}:
///     authorId: String
///     authorName: String
///     authorPhoto: String?
///     content: String
///     mediaUrl: String?      // primary media field
///     mediaType: String?     // "image", "video", etc.
///     imageUrl: String?      // legacy, kept for compatibility
///     timestamp: Timestamp
///     createdAt: Timestamp
///     likeCount: int
///     commentCount: int
///     visibility: String
///
/// Likes & comments are primarily stored in subcollections:
///   community_posts/{postId}/likes/*
///   community_posts/{postId}/comments/*
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final Timestamp timestamp;
  final List<String> likes;
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
    required this.likes,
    required this.comments,
    this.visibility = 'public',
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final commentsData = (data['comments'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(Comment.fromMap)
            .toList() ??
        <Comment>[];

    // Prefer mediaUrl, fall back to legacy imageUrl if present.
    final String? resolvedMediaUrl =
        (data['mediaUrl'] ?? data['imageUrl']) as String?;

    return Post(
      id: doc.id,
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? '').toString(),
      authorPhoto: data['authorPhoto'] as String?,
      content: (data['content'] ?? '').toString(),
      mediaUrl: resolvedMediaUrl,
      mediaType: data['mediaType'] as String?,
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? const <String>[]),
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
      // Keep legacy field in sync in case anything still reads imageUrl.
      'imageUrl': mediaUrl,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments.map((c) => c.toMap()).toList(),
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
          ? map['timestamp'] as Timestamp
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
