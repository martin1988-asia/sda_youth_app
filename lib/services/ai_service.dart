import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = "http://localhost:3000";

  static const Duration timeout = Duration(seconds: 10);

  // ===============================
  // SEND POST TO AI
  // ===============================
  static Future<void> sendPost({
    required String id,
    required String content,
    required String author,
    int likes = 0,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/post"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "id": id,
              "content": content,
              "author": author,
              "likes": likes,
            }),
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        debugPrint("AI post failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("AI post error: $e");
    }
  }

  // ===============================
  // GET AI FEED
  // ===============================
  static Future<List<dynamic>> getFeed({required String userId}) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/feed"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"userId": userId}),
          )
          .timeout(timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        return [];
      }

      debugPrint("AI feed failed: ${res.statusCode}");
      return [];
    } catch (e) {
      debugPrint("AI feed error: $e");
      return [];
    }
  }

  // ===============================
  // SEND USER INTERACTION
  // ===============================
  static Future<void> sendInteraction({
    required String userId,
    required String content,
    double weight = 1,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/interaction"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "userId": userId,
              "content": content,
              "weight": weight,
            }),
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        debugPrint("AI interaction failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("AI interaction error: $e");
    }
  }
}
