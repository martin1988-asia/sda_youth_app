/**
 * One-time script to backfill posts, comments, and favorites with valid userId and timestamp
 * Run with: node fixData.js
 */

const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

const db = admin.firestore();

async function fixPosts() {
  console.log("Checking posts...");
  const postsSnap = await db.collection("posts").get();
  let fixedPosts = 0, fixedComments = 0;

  for (const doc of postsSnap.docs) {
    const data = doc.data();
    const updates = {};
    let needsUpdate = false;

    if (!data.userId || data.userId.trim() === "") {
      updates.userId = "system";
      needsUpdate = true;
    }
    if (!data.timestamp) {
      updates.timestamp = admin.firestore.FieldValue.serverTimestamp();
      needsUpdate = true;
    }

    if (needsUpdate) {
      await doc.ref.update(updates);
      fixedPosts++;
      console.log(`Fixed post ${doc.id}`);
    }

    // Fix comments under each post
    const commentsSnap = await doc.ref.collection("comments").get();
    for (const c of commentsSnap.docs) {
      const cData = c.data();
      const cUpdates = {};
      let cNeedsUpdate = false;

      if (!cData.userId || cData.userId.trim() === "") {
        cUpdates.userId = "system";
        cNeedsUpdate = true;
      }
      if (!cData.timestamp) {
        cUpdates.timestamp = admin.firestore.FieldValue.serverTimestamp();
        cNeedsUpdate = true;
      }

      if (cNeedsUpdate) {
        await c.ref.update(cUpdates);
        fixedComments++;
        console.log(`Fixed comment ${c.id} in post ${doc.id}`);
      }
    }
  }
  console.log(`Posts fixed: ${fixedPosts}, Comments fixed: ${fixedComments}`);
}

async function fixFavorites() {
  console.log("Checking favorites...");
  const favsSnap = await db.collection("favorites").get();
  let fixedFavs = 0;

  for (const doc of favsSnap.docs) {
    const data = doc.data();
    const updates = {};
    let needsUpdate = false;

    if (!data.userId || data.userId.trim() === "") {
      updates.userId = "system";
      needsUpdate = true;
    }
    if (!data.timestamp) {
      updates.timestamp = admin.firestore.FieldValue.serverTimestamp();
      needsUpdate = true;
    }

    if (needsUpdate) {
      await doc.ref.update(updates);
      fixedFavs++;
      console.log(`Fixed favorite ${doc.id}`);
    }
  }
  console.log(`Favorites fixed: ${fixedFavs}`);
}

async function run() {
  await fixPosts();
  await fixFavorites();
  console.log("Backfill complete!");
}

run().catch((err) => {
  console.error("Error fixing data:", err);
});
