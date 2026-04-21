/**
 * Migration script: Move favorites from users/{uid}/favorites
 * into top-level favorites/{uid_devotionalId}
 *
 * Run with: node migrateFavorites.js
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin SDK using your local service account file
admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

const db = admin.firestore();

async function migrateFavorites() {
  console.log("Starting favorites migration...");

  const usersSnap = await db.collection("users").get();

  for (const userDoc of usersSnap.docs) {
    const uid = userDoc.id;
    const favsSnap = await db.collection("users").doc(uid).collection("favorites").get();

    if (favsSnap.empty) {
      continue;
    }

    for (const favDoc of favsSnap.docs) {
      const devotionalId = favDoc.id;
      const data = favDoc.data();

      const newFavRef = db.collection("favorites").doc(`${uid}_${devotionalId}`);

      await newFavRef.set({
        userId: uid,
        devotionalId: devotionalId,
        timestamp: data.timestamp || new Date().toISOString(),
      });

      console.log(`Migrated favorite: user=${uid}, devotional=${devotionalId}`);

      // Delete old doc to keep database clean
      await favDoc.ref.delete();
    }
  }

  console.log("Migration complete!");
}

migrateFavorites().catch((err) => {
  console.error("Migration failed:", err);
});
