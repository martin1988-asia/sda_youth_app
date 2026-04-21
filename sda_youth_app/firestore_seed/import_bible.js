const admin = require("firebase-admin");
const fs = require("fs");

// Load service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Load Genesis JSON
const genesis = JSON.parse(fs.readFileSync("firestore_seed/genesis_kjv.json", "utf8"));

async function importGenesis() {
  const chapters = genesis.bible.kjv.books.Genesis.chapters;

  for (const [chapterNumber, chapterData] of Object.entries(chapters)) {
    const verses = chapterData.verses;
    for (const [verseNumber, verseData] of Object.entries(verses)) {
      await db
        .collection("bible")
        .doc("kjv")
        .collection("books")
        .doc("Genesis")
        .collection("chapters")
        .doc(chapterNumber)
        .collection("verses")
        .doc(verseNumber)
        .set(verseData);
      console.log(`Imported Genesis ${chapterNumber}:${verseNumber}`);
    }
  }
}

importGenesis().then(() => {
  console.log("Genesis import complete!");
  process.exit(0);
});
