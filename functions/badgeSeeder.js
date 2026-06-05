const admin = require("firebase-admin");

/**
 * Seeds badge definitions into Firestore.
 * Run once locally with: node badgeSeeder.js
 */
const badges = [
  {
    badgeId: "Daniel7Complete",
    title: "Daniel 7-Day Streak",
    description: "Completed all 7 days of the Daniel Bible plan",
    criteria: "Finish all days in planId=daniel7",
    iconUrl: "/assets/badges/daniel7.png",
    category: "streak",
    points: 50,
    createdAt: new Date().toISOString(),
  },
  {
    badgeId: "PrayerPartnerWeek",
    title: "Prayer Partner",
    description: "Shared daily praise and request with your partner for 7 days",
    criteria: "Complete prayerPartner streak",
    iconUrl: "/assets/badges/prayer.png",
    category: "community",
    points: 30,
    createdAt: new Date().toISOString(),
  },
];

exports.seedBadgeDefinitions = async () => {
  const batch = admin.firestore().batch();
  const col = admin.firestore().collection("gamification");

  badges.forEach((badge) => {
    const ref = col.doc(badge.badgeId);
    batch.set(ref, badge);
  });

  await batch.commit();
  console.log("Seeded badge definitions");
};
