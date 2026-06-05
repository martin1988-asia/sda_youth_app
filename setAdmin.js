const admin = require("firebase-admin");

// Load your service account key
const serviceAccount = require("./sda-youth-app-firebase-adminsdk-fbsvc-42f1b5fc8b.json");

// Initialize the app
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// The UID of the user you want to make admin
const uid = "N9sqaTxPepYKE0dog0dqKW0qR6i1";

// Set custom claims
admin.auth().setCustomUserClaims(uid, { role: "admin" })
  .then(() => {
    console.log(`✅ Successfully set admin role for user ${uid}`);
    process.exit(0);
  })
  .catch(error => {
    console.error("❌ Error setting custom claims:", error);
    process.exit(1);
  });

