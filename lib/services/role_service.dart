// lib/services/role_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sda_youth_app/core/user_role.dart';

class RoleService {
  static UserRole? _activeRoleCache;
  static final _roleController = StreamController<UserRole>.broadcast();

  static Stream<UserRole> get identityRoleStream => _roleController.stream;

  static UserRole get currentUserRole => _activeRoleCache ?? UserRole.user;

  // --- Legacy and new API compatibility ---

  static Future<UserRole> getUserRole() => getAuthorizedRole();

  static Future<UserRole> loadUserRole() => getAuthorizedRole();

  static Future<UserRole> getAuthorizedRole() async {
    if (_activeRoleCache != null) return _activeRoleCache!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserRole.user;

    try {
      final tokenResult = await user.getIdTokenResult();
      final claims = tokenResult.claims;
      final roleClaim = (claims?['role'])?.toString();
      if (roleClaim != null && roleClaim.isNotEmpty) {
        final role = _mapRoleString(roleClaim);
        await _persistRole(role);
        _activeRoleCache = role;
        _roleController.add(role);
        await FirebaseAnalytics.instance.logEvent(name: 'role_claim_loaded', parameters: {'role': role.name});
        return role;
      }
    } catch (e, st) {
      _logError(e, st, 'getIdTokenResult_failed');
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final roleString = (doc.data()?['role'])?.toString() ?? 'user';
      final role = _mapRoleString(roleString);
      await _persistRole(role);
      _activeRoleCache = role;
      _roleController.add(role);
      await FirebaseAnalytics.instance.logEvent(name: 'role_firestore_loaded', parameters: {'role': role.name});
      return role;
    } catch (e, st) {
      _logError(e, st, 'role_firestore_read_failed');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cachedRole');
      if (cached != null && cached.isNotEmpty) {
        final role = UserRole.values.firstWhere(
          (r) => r.name == cached,
          orElse: () => UserRole.user,
        );
        _activeRoleCache = role;
        _roleController.add(role);
        return role;
      }
    } catch (_) {}

    _activeRoleCache = UserRole.user;
    _roleController.add(UserRole.user);
    return UserRole.user;
  }

  static Future<void> setUserRole(UserRole role) async {
    _activeRoleCache = role;
    _roleController.add(role);
    await _persistRole(role);
    await FirebaseAnalytics.instance.logEvent(name: 'role_set', parameters: {'role': role.name});
  }

  static Future<void> clearRole() async {
    _activeRoleCache = null;
    _roleController.add(UserRole.user);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cachedRole');
    } catch (_) {}
    await FirebaseAnalytics.instance.logEvent(name: 'role_cleared');
  }

  static bool isAdmin() => _activeRoleCache == UserRole.admin;
  static bool isModerator() => _activeRoleCache == UserRole.moderator;
  static bool isEditor() => _activeRoleCache == UserRole.editor;
  static bool isUser() => _activeRoleCache == UserRole.user;

  static UserRole _mapRoleString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      case 'editor':
        return UserRole.editor;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  static Future<void> _persistRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedRole', role.name);
  }

  static void _logError(Object e, StackTrace st, String reason) async {
    try {
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.recordError(e, st, reason: reason);
      }
    } catch (_) {}
  }
}
