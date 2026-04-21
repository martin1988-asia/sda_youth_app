#!/bin/bash

# Fix imports for NotificationsHelper across the project

# For files in lib/home/
sed -i '1i import "../notifications_helper.dart";' lib/home/friends_page.dart
sed -i '1i import "../notifications_helper.dart";' lib/home/home_page.dart
sed -i '1i import "../notifications_helper.dart";' lib/home/create_post.dart

# For files in lib/features/devotionals/
sed -i '1i import "../../notifications_helper.dart";' lib/features/devotionals/devotionals_page.dart

# For main.dart
sed -i '1i import "notifications_helper.dart";' lib/main.dart
