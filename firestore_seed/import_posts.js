const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load posts JSON
const posts = JSON.parse(fs.readFileSync("firestore_seed/posts.json", "utf8")).posts;

async function importPosts() {
  for (const [id, post] of Object.entries(posts)) {
    await db.collection("posts").doc(id).set(post);
    console.log(`Imported post: ${id}`);
  }
}

importPosts().then(() => {
  console.log("Posts import complete!");
  process.exit(0);
});
