const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load events JSON
const events = JSON.parse(fs.readFileSync("firestore_seed/events.json", "utf8")).events;

async function importEvents() {
  for (const [id, event] of Object.entries(events)) {
    await db.collection("events").doc(id).set(event);
    console.log(`Imported event: ${id}`);
  }
}

importEvents().then(() => {
  console.log("Events import complete!");
  process.exit(0);
});
