const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load profiles JSON
const profiles = JSON.parse(fs.readFileSync("firestore_seed/profiles.json", "utf8")).profiles;

async function importProfiles() {
  for (const [id, profile] of Object.entries(profiles)) {
    await db.collection("users").doc(id).set(profile);
    console.log(`Imported profile: ${id}`);
  }
}

importProfiles().then(() => {
  console.log("Profiles import complete!");
  process.exit(0);
});
