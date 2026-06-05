/// Centralized role definitions for the SDA Youth App.
/// All files should import this instead of redefining UserRole.
///
/// This enum is the single source of truth for Role‑Based Access Control (RBAC).
/// Each role is documented with its intended privileges.
///
/// ✅ Analyzer‑clean
/// ✅ Production‑ready
/// ✅ Easy to extend in the future
enum UserRole {
  /// Full administrative privileges:
  /// - Manage users
  /// - Moderate content
  /// - Access analytics
  /// - Configure system settings
  admin,

  /// Moderation privileges:
  /// - Review posts
  /// - Handle reports
  /// - Enforce community rules
  moderator,

  /// Content editing privileges:
  /// - Create and manage posts
  /// - Publish lessons and devotionals
  /// - Edit announcements and events
  editor,

  /// Elder privileges:
  /// - Answer questions in Ask an Elder
  /// - Provide spiritual guidance
  /// - Moderate testimonies and prayer requests
  elder,

  /// Leader privileges:
  /// - Manage groups and events
  /// - Approve answers in Ask an Elder
  /// - Oversee community initiatives
  leader,

  /// Standard user privileges:
  /// - Access core features
  /// - Create posts
  /// - Interact socially
  user,
}
