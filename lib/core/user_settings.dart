import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class UserSettings {
  // ================= CORE =================
  bool notificationsEnabled;
  bool darkModeEnabled;

  // ================= PRIVACY =================
  bool privateAccount;
  bool allowMessages;

  // ================= NOTIFICATIONS =================
  bool notifyLikes;
  bool notifyComments;
  bool notifyMessages;

  // ================= REELS =================
  bool autoplay;
  bool muteByDefault;

  // ================= ADVANCED / SYSTEM =================
  bool twoFactorEnabled;
  bool biometricEnabled;
  bool dataSaverEnabled;
  bool backgroundRefreshEnabled;

  // ================= DATA / ANALYTICS =================
  bool shareDataEnabled;
  bool analyticsEnabled;
  bool personalizedAdsEnabled;

  // ================= OPTIMIZATION =================
  bool lowQualityImages;

  // ================= META =================
  DateTime lastUpdated;
  int settingsVersion;

  UserSettings({
    // core
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,

    // privacy
    this.privateAccount = false,
    this.allowMessages = true,

    // notifications
    this.notifyLikes = true,
    this.notifyComments = true,
    this.notifyMessages = true,

    // reels
    this.autoplay = true,
    this.muteByDefault = false,

    // advanced
    this.twoFactorEnabled = false,
    this.biometricEnabled = false,
    this.dataSaverEnabled = false,
    this.backgroundRefreshEnabled = true,

    // data
    this.shareDataEnabled = true,
    this.analyticsEnabled = true,
    this.personalizedAdsEnabled = false,

    // optimization
    this.lowQualityImages = false,

    DateTime? lastUpdated,
    this.settingsVersion = 1,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // ✅ DEFAULTS
  static UserSettings defaults() => UserSettings();

  // ================= LOCAL =================
  static Future<UserSettings> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();

    return UserSettings(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      darkModeEnabled: prefs.getBool('darkModeEnabled') ?? false,

      privateAccount: prefs.getBool('privateAccount') ?? false,
      allowMessages: prefs.getBool('allowMessages') ?? true,

      notifyLikes: prefs.getBool('notifyLikes') ?? true,
      notifyComments: prefs.getBool('notifyComments') ?? true,
      notifyMessages: prefs.getBool('notifyMessages') ?? true,

      autoplay: prefs.getBool('autoplay') ?? true,
      muteByDefault: prefs.getBool('muteByDefault') ?? false,

      twoFactorEnabled: prefs.getBool('twoFactorEnabled') ?? false,
      biometricEnabled: prefs.getBool('biometricEnabled') ?? false,
      dataSaverEnabled: prefs.getBool('dataSaverEnabled') ?? false,
      backgroundRefreshEnabled:
          prefs.getBool('backgroundRefreshEnabled') ?? true,

      shareDataEnabled: prefs.getBool('shareDataEnabled') ?? true,
      analyticsEnabled: prefs.getBool('analyticsEnabled') ?? true,
      personalizedAdsEnabled:
          prefs.getBool('personalizedAdsEnabled') ?? false,

      lowQualityImages: prefs.getBool('lowQualityImages') ?? false,

      lastUpdated: DateTime.tryParse(
              prefs.getString('lastUpdated') ?? '') ??
          DateTime.now(),
      settingsVersion: prefs.getInt('settingsVersion') ?? 1,
    );
  }

  Future<void> saveLocal() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('darkModeEnabled', darkModeEnabled);

    await prefs.setBool('privateAccount', privateAccount);
    await prefs.setBool('allowMessages', allowMessages);

    await prefs.setBool('notifyLikes', notifyLikes);
    await prefs.setBool('notifyComments', notifyComments);
    await prefs.setBool('notifyMessages', notifyMessages);

    await prefs.setBool('autoplay', autoplay);
    await prefs.setBool('muteByDefault', muteByDefault);

    await prefs.setBool('twoFactorEnabled', twoFactorEnabled);
    await prefs.setBool('biometricEnabled', biometricEnabled);
    await prefs.setBool('dataSaverEnabled', dataSaverEnabled);
    await prefs.setBool(
        'backgroundRefreshEnabled', backgroundRefreshEnabled);

    await prefs.setBool('shareDataEnabled', shareDataEnabled);
    await prefs.setBool('analyticsEnabled', analyticsEnabled);
    await prefs.setBool(
        'personalizedAdsEnabled', personalizedAdsEnabled);

    await prefs.setBool('lowQualityImages', lowQualityImages);

    await prefs.setString(
        'lastUpdated', DateTime.now().toIso8601String());
    await prefs.setInt('settingsVersion', settingsVersion);
  }

  // ================= CLOUD =================
  static Future<UserSettings> loadCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return UserSettings.defaults();

      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (!doc.exists) return UserSettings.defaults();

      return fromJson(doc.data()!);
    } catch (e, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, stack);
      }
      return UserSettings.defaults();
    }
  }

  Future<void> saveCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    settingsVersion++;

    await FirebaseFirestore.instance
        .collection('settings')
        .doc(user.uid)
        .set({
      ...toJson(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'settingsVersion': settingsVersion,
    }, SetOptions(merge: true));

    FirebaseAnalytics.instance.logEvent(
      name: 'settings_updated',
      parameters: {'version': settingsVersion},
    );
  }

  // ================= JSON =================
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,

      'privateAccount': privateAccount,
      'allowMessages': allowMessages,

      'notifyLikes': notifyLikes,
      'notifyComments': notifyComments,
      'notifyMessages': notifyMessages,

      'autoplay': autoplay,
      'muteByDefault': muteByDefault,

      'twoFactorEnabled': twoFactorEnabled,
      'biometricEnabled': biometricEnabled,
      'dataSaverEnabled': dataSaverEnabled,
      'backgroundRefreshEnabled': backgroundRefreshEnabled,

      'shareDataEnabled': shareDataEnabled,
      'analyticsEnabled': analyticsEnabled,
      'personalizedAdsEnabled': personalizedAdsEnabled,

      'lowQualityImages': lowQualityImages,

      'lastUpdated': lastUpdated.toIso8601String(),
      'settingsVersion': settingsVersion,
    };
  }

  static UserSettings fromJson(Map<String, dynamic> data) {
    return UserSettings(
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      darkModeEnabled: data['darkModeEnabled'] ?? false,

      privateAccount: data['privateAccount'] ?? false,
      allowMessages: data['allowMessages'] ?? true,

      notifyLikes: data['notifyLikes'] ?? true,
      notifyComments: data['notifyComments'] ?? true,
      notifyMessages: data['notifyMessages'] ?? true,

      autoplay: data['autoplay'] ?? true,
      muteByDefault: data['muteByDefault'] ?? false,

      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      biometricEnabled: data['biometricEnabled'] ?? false,
      dataSaverEnabled: data['dataSaverEnabled'] ?? false,
      backgroundRefreshEnabled:
          data['backgroundRefreshEnabled'] ?? true,

      shareDataEnabled: data['shareDataEnabled'] ?? true,
      analyticsEnabled: data['analyticsEnabled'] ?? true,
      personalizedAdsEnabled:
          data['personalizedAdsEnabled'] ?? false,

      lowQualityImages: data['lowQualityImages'] ?? false,

      lastUpdated: (data['lastUpdated'] is String)
          ? DateTime.tryParse(data['lastUpdated']) ??
              DateTime.now()
          : (data['lastUpdated'] is Timestamp)
              ? (data['lastUpdated'] as Timestamp).toDate()
              : DateTime.now(),

      settingsVersion: data['settingsVersion'] ?? 1,
    );
  }
}
