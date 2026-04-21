/**
 * One-time script to backfill posts with a valid userId
 * Run with: node fixPosts.js
 */

const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

const db = admin.firestore();

async function fixPosts() {
  console.log("Checking posts for missing userId...");

  const postsSnap = await db.collection("posts").get();
  let fixedCount = 0;

  for (const doc of postsSnap.docs) {
    const data = doc.data();
    const userId = data.userId;

    if (!userId || userId.trim() === "") {
      await doc.ref.update({
        userId: "system", // fallback value
      });
      fixedCount++;
      console.log(`Fixed post ${doc.id} → userId set to "system"`);
    }
  }

  console.log(`Done. Fixed ${fixedCount} posts.`);
}

fixPosts().catch((err) => {
  console.error("Error fixing posts:", err);
});
