const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load devotionals JSON
const devotionals = JSON.parse(fs.readFileSync("firestore_seed/devotionals.json", "utf8")).devotionals;

async function importDevotionals() {
  for (const [id, devo] of Object.entries(devotionals)) {
    await db.collection("devotionals").doc(id).set(devo);
    console.log(`Imported devotional: ${id}`);
  }
}

importDevotionals().then(() => {
  console.log("Devotionals import complete!");
  process.exit(0);
});
