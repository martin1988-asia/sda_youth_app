const {onSchedule} = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Use env vars locally; in production functions.config().gmail is fallback
const gmailConfig = functions.config && functions.config().gmail ?
  functions.config().gmail :
  null;
const gmailUser = process.env.GMAIL_USER ||
  (gmailConfig ? gmailConfig.user : null);
const gmailPass = process.env.GMAIL_PASS ||
  (gmailConfig ? gmailConfig.pass : null);

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailUser,
    pass: gmailPass,
  },
});

/**
 * Weekly digest for parents of under‑16 users.
 */
exports.weeklyParentDigest = onSchedule(
    {
      schedule: "every sunday 18:00",
      timeZone: "Africa/Windhoek",
    },
    async () => {
      try {
        const usersSnap = await admin
            .firestore()
            .collection("users")
            .where("age", "<", 16)
            .get();

        for (const doc of usersSnap.docs) {
          const user = doc.data();
          const parentEmail = user && user.parentEmail;

          if (!parentEmail) {
            continue;
          }

          const digestLines = [
            `Summary for ${user.displayName || user.name || "Child"}:`,
            `- Streaks: ${user.streakCount || 0}`,
            `- Badges: ${(user.badges || []).join(", ") || "None"}`,
            `- Posts this week: ${user.postsCount || 0}`,
          ];

          const digest = digestLines.join("\n");

          try {
            await transporter.sendMail({
              from: "noreply@sda-youth-app.com",
              to: parentEmail,
              subject: "Weekly Youth App Digest",
              text: digest,
            });
            console.log("Sent digest to", parentEmail);
          } catch (mailErr) {
            console.error("Failed to send digest to", parentEmail, mailErr);
          }
        }

        return null;
      } catch (err) {
        console.error("weeklyParentDigest error", err);
        return null;
      }
    },
);
