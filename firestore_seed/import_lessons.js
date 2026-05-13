const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load lessons JSON
const lessons = JSON.parse(fs.readFileSync("firestore_seed/lessons.json", "utf8")).lessons;

async function importLessons() {
  for (const [id, lesson] of Object.entries(lessons)) {
    await db.collection("lessons").doc(id).set(lesson);
    console.log(`Imported lesson: ${id}`);
  }
}

importLessons().then(() => {
  console.log("Lessons import complete!");
  process.exit(0);
});
