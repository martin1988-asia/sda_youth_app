const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load announcements JSON
const announcements = JSON.parse(fs.readFileSync("firestore_seed/announcements.json", "utf8")).announcements;

async function importAnnouncements() {
  for (const [id, ann] of Object.entries(announcements)) {
    await db.collection("announcements").doc(id).set(ann);
    console.log(`Imported announcement: ${id}`);
  }
}

importAnnouncements().then(() => {
  console.log("Announcements import complete!");
  process.exit(0);
});
