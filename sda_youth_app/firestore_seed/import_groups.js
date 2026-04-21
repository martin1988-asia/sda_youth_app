const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load groups JSON
const groups = JSON.parse(fs.readFileSync("firestore_seed/groups.json", "utf8")).groups;

async function importGroups() {
  for (const [id, group] of Object.entries(groups)) {
    await db.collection("groups").doc(id).set(group);
    console.log(`Imported group: ${id}`);
  }
}

importGroups().then(() => {
  console.log("Groups import complete!");
  process.exit(0);
});
