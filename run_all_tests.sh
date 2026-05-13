#!/bin/bash
set -e

echo "🚀 Running full SDA Youth App test suite..."

# Run unit/widget tests
echo "▶️ Running widget/unit tests..."
flutter test test/full_app_test.dart

# Run friends + posts tests
echo "▶️ Running friends + posts tests..."
flutter test test/friends_posts_test.dart

# Run admin RBAC tests
echo "▶️ Running admin RBAC tests..."
flutter test test/admin_flow_test.dart

# Run community + messages + notifications tests
echo "▶️ Running community/messages/notifications tests..."
flutter test test/community_messages_test.dart

# Run events + media uploads tests
echo "▶️ Running events/media tests..."
flutter test test/events_media_test.dart

echo "✅ All test suites executed successfully!"
