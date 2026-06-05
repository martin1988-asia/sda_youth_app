import 'package:flutter/foundation.dart' show debugPrint;

class ModerationResult {
  final bool isAllowed;
  final bool shouldWarn;
  final bool isBlocked;
  final String message;
  final String category;
  final int severity;

  const ModerationResult({
    required this.isAllowed,
    required this.shouldWarn,
    required this.isBlocked,
    required this.message,
    required this.category,
    required this.severity,
  });
}

class ModerationService {
  /* =====================================================
     🔒 BLOCKED KEYWORDS (STRICT)
  ===================================================== */

  static const List<String> _blockedWords = [
    "hate",
    "kill",
    "violence",
    "porn",
    "nsfw",
    "abuse",
  ];

  /* =====================================================
     ⚠️ SOFT WARNING WORDS (GUIDANCE)
  ===================================================== */

  static const List<String> _warningWords = [
    "anger",
    "argument",
    "fight",
    "insult",
  ];

  /* =====================================================
     ✝️ FAITH KEYWORDS
  ===================================================== */

  static const List<String> _faithWords = [
    "jesus",
    "god",
    "bible",
    "prayer",
    "faith",
    "blessing",
    "scripture",
    "church",
    "amen",
  ];

  /* =====================================================
     🧠 MAIN MODERATION ENTRY
  ===================================================== */

  static Future<ModerationResult> moderate(String text) async {
    final cleaned = text.toLowerCase().trim();

    // ✅ Empty safety
    if (cleaned.isEmpty) {
      return const ModerationResult(
        isAllowed: false,
        shouldWarn: true,
        isBlocked: true,
        message: "Post cannot be empty",
        category: "invalid",
        severity: 10,
      );
    }

    // ✅ Hard block
    for (final word in _blockedWords) {
      if (cleaned.contains(word)) {
        return ModerationResult(
          isAllowed: false,
          shouldWarn: false,
          isBlocked: true,
          message: "This content is not appropriate for this community.",
          category: "blocked",
          severity: 9,
        );
      }
    }

    // ✅ Soft warning
    for (final word in _warningWords) {
      if (cleaned.contains(word)) {
        return ModerationResult(
          isAllowed: true,
          shouldWarn: true,
          isBlocked: false,
          message: "This may not reflect a positive or uplifting message.",
          category: "warning",
          severity: 5,
        );
      }
    }

    // ✅ Faith detection
    if (_containsFaith(cleaned)) {
      return ModerationResult(
        isAllowed: true,
        shouldWarn: false,
        isBlocked: false,
        message: "",
        category: "faith",
        severity: 1,
      );
    }

    // ✅ Neutral content
    return ModerationResult(
      isAllowed: true,
      shouldWarn: false,
      isBlocked: false,
      message: "",
      category: "general",
      severity: 0,
    );
  }

  /* =====================================================
     ✝️ FAITH DETECTION
  ===================================================== */

  static bool _containsFaith(String text) {
    for (final word in _faithWords) {
      if (text.contains(word)) return true;
    }
    return false;
  }

  /* =====================================================
     🤖 AI MODERATION HOOK
  ===================================================== */

  static Future<ModerationResult> runAdvancedModeration(String text) async {
    try {
      // 🔥 Placeholder for real AI (OpenAI / Azure / etc)

      final basic = await moderate(text);

      // 👇 Example future upgrade
      /*
      final aiResult = await callAI(text);

      if (!aiResult.safe) {
        return ModerationResult(
          isAllowed: false,
          shouldWarn: false,
          isBlocked: true,
          message: aiResult.reason,
          category: "ai_block",
          severity: 10,
        );
      }
      */

      return basic;
    } catch (e) {
      debugPrint("AI moderation error: $e");

      return const ModerationResult(
        isAllowed: true,
        shouldWarn: false,
        isBlocked: false,
        message: "",
        category: "fallback",
        severity: 0,
      );
    }
  }
}
