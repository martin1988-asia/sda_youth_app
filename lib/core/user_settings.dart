import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  bool notificationsEnabled;
  bool darkModeEnabled;
  bool twoFactorEnabled;
  bool biometricEnabled;
  bool dataSaverEnabled;
  bool backgroundRefreshEnabled;

  // Extra fields for privacy/data saver pages
  bool shareDataEnabled;
  bool analyticsEnabled;
  bool personalizedAdsEnabled;
  bool lowQualityImages;
  bool disableAutoPlayVideos;

  DateTime lastUpdated;
  int settingsVersion;

  UserSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.twoFactorEnabled = false,
    this.biometricEnabled = false,
    this.dataSaverEnabled = false,
    this.backgroundRefreshEnabled = true,
    this.shareDataEnabled = true,
    this.analyticsEnabled = true,
    this.personalizedAdsEnabled = false,
    this.lowQualityImages = false,
    this.disableAutoPlayVideos = false,
    DateTime? lastUpdated,
    this.settingsVersion = 1,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Defaults
  static UserSettings defaults() => UserSettings();

  /// Load settings from SharedPreferences (local)
  static Future<UserSettings> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      darkModeEnabled: prefs.getBool('darkModeEnabled') ?? false,
      twoFactorEnabled: prefs.getBool('twoFactorEnabled') ?? false,
      biometricEnabled: prefs.getBool('biometricEnabled') ?? false,
      dataSaverEnabled: prefs.getBool('dataSaverEnabled') ?? false,
      backgroundRefreshEnabled: prefs.getBool('backgroundRefreshEnabled') ?? true,
      shareDataEnabled: prefs.getBool('shareDataEnabled') ?? true,
      analyticsEnabled: prefs.getBool('analyticsEnabled') ?? true,
      personalizedAdsEnabled: prefs.getBool('personalizedAdsEnabled') ?? false,
      lowQualityImages: prefs.getBool('lowQualityImages') ?? false,
      disableAutoPlayVideos: prefs.getBool('disableAutoPlayVideos') ?? false,
      lastUpdated: DateTime.tryParse(prefs.getString('lastUpdated') ?? '') ?? DateTime.now(),
      settingsVersion: prefs.getInt('settingsVersion') ?? 1,
    );
  }

  /// Save settings to SharedPreferences (local)
  Future<void> saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('darkModeEnabled', darkModeEnabled);
    await prefs.setBool('twoFactorEnabled', twoFactorEnabled);
    await prefs.setBool('biometricEnabled', biometricEnabled);
    await prefs.setBool('dataSaverEnabled', dataSaverEnabled);
    await prefs.setBool('backgroundRefreshEnabled', backgroundRefreshEnabled);
    await prefs.setBool('shareDataEnabled', shareDataEnabled);
    await prefs.setBool('analyticsEnabled', analyticsEnabled);
    await prefs.setBool('personalizedAdsEnabled', personalizedAdsEnabled);
    await prefs.setBool('lowQualityImages', lowQualityImages);
    await prefs.setBool('disableAutoPlayVideos', disableAutoPlayVideos);
    await prefs.setString('lastUpdated', lastUpdated.toIso8601String());
    await prefs.setInt('settingsVersion', settingsVersion);
  }

  /// Load settings from Firestore (cloud)
  static Future<UserSettings> loadCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return UserSettings.defaults();

      final doc = await FirebaseFirestore.instance.collection('settings').doc(user.uid).get();
      if (!doc.exists) return UserSettings.defaults();

      final data = doc.data()!;
      return UserSettings(
        notificationsEnabled: data['notificationsEnabled'] ?? true,
        darkModeEnabled: data['darkModeEnabled'] ?? false,
        twoFactorEnabled: data['twoFactorEnabled'] ?? false,
        biometricEnabled: data['biometricEnabled'] ?? false,
        dataSaverEnabled: data['dataSaverEnabled'] ?? false,
        backgroundRefreshEnabled: data['backgroundRefreshEnabled'] ?? true,
        shareDataEnabled: data['shareDataEnabled'] ?? true,
        analyticsEnabled: data['analyticsEnabled'] ?? true,
        personalizedAdsEnabled: data['personalizedAdsEnabled'] ?? false,
        lowQualityImages: data['lowQualityImages'] ?? false,
        disableAutoPlayVideos: data['disableAutoPlayVideos'] ?? false,
        lastUpdated: (data['lastUpdated'] is Timestamp)
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.tryParse(data['lastUpdated'] ?? '') ?? DateTime.now(),
        settingsVersion: data['settingsVersion'] ?? 1,
      );
    } catch (_) {
      return UserSettings.defaults();
    }
  }

  /// Save settings to Firestore (cloud)
  Future<void> saveCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'twoFactorEnabled': twoFactorEnabled,
      'biometricEnabled': biometricEnabled,
      'dataSaverEnabled': dataSaverEnabled,
      'backgroundRefreshEnabled': backgroundRefreshEnabled,
      'shareDataEnabled': shareDataEnabled,
      'analyticsEnabled': analyticsEnabled,
      'personalizedAdsEnabled': personalizedAdsEnabled,
      'lowQualityImages': lowQualityImages,
      'disableAutoPlayVideos': disableAutoPlayVideos,
      'lastUpdated': FieldValue.serverTimestamp(),
      'settingsVersion': settingsVersion,
    }, SetOptions(merge: true));
  }

  /// Merge local and cloud settings intelligently
  static Future<UserSettings> loadMerged() async {
    final local = await UserSettings.loadLocal();
    final cloud = await UserSettings.loadCloud();
    return cloud.lastUpdated.isAfter(local.lastUpdated) ? cloud : local;
  }

  /// Real-time Firestore stream
  static Stream<UserSettings> streamCloud() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(UserSettings.defaults());

    return FirebaseFirestore.instance
        .collection('settings')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return UserSettings.defaults();
      final data = doc.data()!;
      return UserSettings(
        notificationsEnabled: data['notificationsEnabled'] ?? true,
        darkModeEnabled: data['darkModeEnabled'] ?? false,
        twoFactorEnabled: data['twoFactorEnabled'] ?? false,
        biometricEnabled: data['biometricEnabled'] ?? false,
        dataSaverEnabled: data['dataSaverEnabled'] ?? false,
        backgroundRefreshEnabled: data['backgroundRefreshEnabled'] ?? true,
        shareDataEnabled: data['shareDataEnabled'] ?? true,
        analyticsEnabled: data['analyticsEnabled'] ?? true,
        personalizedAdsEnabled: data['personalizedAdsEnabled'] ?? false,
        lowQualityImages: data['lowQualityImages'] ?? false,
        disableAutoPlayVideos: data['disableAutoPlayVideos'] ?? false,
        lastUpdated: (data['lastUpdated'] is Timestamp)
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.tryParse(data['lastUpdated'] ?? '') ?? DateTime.now(),
        settingsVersion: data['settingsVersion'] ?? 1,
      );
    });
  }

  /// Hybrid stream: local first, then cloud
  static Stream<UserSettings> streamMerged() async* {
    final local = await UserSettings.loadLocal();
    yield local;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    yield* FirebaseFirestore.instance
        .collection('settings')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return local;
      final data = doc.data()!;
      return UserSettings(
        notificationsEnabled: data['notificationsEnabled'] ?? local.notificationsEnabled,
        darkModeEnabled: data['darkModeEnabled'] ?? local.darkModeEnabled,
        twoFactorEnabled: data['twoFactorEnabled'] ?? local.twoFactorEnabled,
        biometricEnabled: data['biometricEnabled'] ?? local.biometricEnabled,
        dataSaverEnabled: data['dataSaverEnabled'] ?? local.dataSaverEnabled,
        backgroundRefreshEnabled: data['backgroundRefreshEnabled'] ?? local.backgroundRefreshEnabled,
        shareDataEnabled: data['shareDataEnabled'] ?? local.shareDataEnabled,
        analyticsEnabled: data['analyticsEnabled'] ?? local.analyticsEnabled,
        personalizedAdsEnabled: data['personalizedAdsEnabled'] ?? local.personalizedAdsEnabled,
        lowQualityImages: data['lowQualityImages'] ?? local.lowQualityImages,
        disableAutoPlayVideos: data['disableAutoPlayVideos'] ?? local.disableAutoPlayVideos,
        lastUpdated: (data['lastUpdated'] is Timestamp)
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.tryParse(data['lastUpdated'] ?? '') ?? local.lastUpdated,
        settingsVersion: data['settingsVersion'] ?? local.settingsVersion,
      );
    });
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    final defaults = UserSettings.defaults();
    notificationsEnabled = defaults.notificationsEnabled;
    darkModeEnabled = defaults.darkModeEnabled;
    twoFactorEnabled = defaults.twoFactorEnabled;
    biometricEnabled = defaults.biometricEnabled;
    dataSaverEnabled = defaults.dataSaverEnabled;
    backgroundRefreshEnabled = defaults.backgroundRefreshEnabled;
    shareDataEnabled = defaults.shareDataEnabled;
    analyticsEnabled = defaults.analyticsEnabled;
    personalizedAdsEnabled = defaults.personalizedAdsEnabled;
    lowQualityImages = defaults.lowQualityImages;
    disableAutoPlayVideos = defaults.disableAutoPlayVideos;
    lastUpdated = DateTime.now();
    settingsVersion = defaults.settingsVersion;

    await saveLocal();
    await saveCloud();
  }

  /// CopyWith helper
  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    bool? dataSaverEnabled,
    bool? backgroundRefreshEnabled,
    bool? shareDataEnabled,
    bool? analyticsEnabled,
    bool? personalizedAdsEnabled,
    bool? lowQualityImages,
    bool? disableAutoPlayVideos,
    DateTime? lastUpdated,
    int? settingsVersion,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      dataSaverEnabled: dataSaverEnabled ?? this.dataSaverEnabled,
      backgroundRefreshEnabled: backgroundRefreshEnabled ?? this.backgroundRefreshEnabled,
      shareDataEnabled: shareDataEnabled ?? this.shareDataEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      personalizedAdsEnabled: personalizedAdsEnabled ?? this.personalizedAdsEnabled,
      lowQualityImages: lowQualityImages ?? this.lowQualityImages,
      disableAutoPlayVideos: disableAutoPlayVideos ?? this.disableAutoPlayVideos,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      settingsVersion: settingsVersion ?? this.settingsVersion,
    );
  }

  /// Convert to JSON (for debugging or API integration)
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'twoFactorEnabled': twoFactorEnabled,
      'biometricEnabled': biometricEnabled,
      'dataSaverEnabled': dataSaverEnabled,
      'backgroundRefreshEnabled': backgroundRefreshEnabled,
      'shareDataEnabled': shareDataEnabled,
      'analyticsEnabled': analyticsEnabled,
      'personalizedAdsEnabled': personalizedAdsEnabled,
      'lowQualityImages': lowQualityImages,
      'disableAutoPlayVideos': disableAutoPlayVideos,
      'lastUpdated': lastUpdated.toIso8601String(),
      'settingsVersion': settingsVersion,
    };
  }

  /// Construct from JSON
  static UserSettings fromJson(Map<String, dynamic> data) {
    return UserSettings(
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      darkModeEnabled: data['darkModeEnabled'] ?? false,
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      biometricEnabled: data['biometricEnabled'] ?? false,
      dataSaverEnabled: data['dataSaverEnabled'] ?? false,
      backgroundRefreshEnabled: data['backgroundRefreshEnabled'] ?? true,
      shareDataEnabled: data['shareDataEnabled'] ?? true,
      analyticsEnabled: data['analyticsEnabled'] ?? true,
      personalizedAdsEnabled: data['personalizedAdsEnabled'] ?? false,
      lowQualityImages: data['lowQualityImages'] ?? false,
      disableAutoPlayVideos: data['disableAutoPlayVideos'] ?? false,
      lastUpdated: (data['lastUpdated'] is String)
          ? DateTime.tryParse(data['lastUpdated']) ?? DateTime.now()
          : (data['lastUpdated'] is Timestamp)
              ? (data['lastUpdated'] as Timestamp).toDate()
              : DateTime.now(),
      settingsVersion: data['settingsVersion'] ?? 1,
    );
  }
}

