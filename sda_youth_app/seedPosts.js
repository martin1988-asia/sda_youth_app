/**
 * Seed Firestore with safe default posts
 * Run with: node seedPosts.js
 */

const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

const db = admin.firestore();

async function seedPosts() {
  console.log("Seeding Firestore posts...");

  const posts = [
    {
      title: "Welcome to SDA Youth App",
      body: "This is your first post. Share devotionals, events, and connect with friends!",
      userId: "system",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      shares: 0,
      reactions: {},
    },
    {
      title: "Daily Devotional",
      body: "Remember to check today’s devotional and add it to your favorites.",
      userId: "system",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      shares: 0,
      reactions: {},
    },
  ];

  for (const post of posts) {
    const ref = db.collection("posts").doc();
    await ref.set(post);
    console.log(`Seeded post: ${post.title}`);
  }

  console.log("Seeding complete!");
}

seedPosts().catch((err) => {
  console.error("Seeding failed:", err);
});
