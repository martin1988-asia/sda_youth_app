const admin = require("firebase-admin");

// Load your service account key
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Replace with your admin UID from Firebase Authentication
const uid = "N9sqaTxPepYKE0dogQdqKWQqR6i1";

async function setAdminClaim() {
  await admin.auth().setCustomUserClaims(uid, { role: "admin" });
  console.log(`✅ Custom claim set: ${uid} is now an admin`);
}

setAdminClaim();
