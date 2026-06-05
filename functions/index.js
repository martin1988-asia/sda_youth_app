/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const {awardStreakBadge} = require("./streakBadge");
const {weeklyParentDigest} = require("./parentDigest");
const {seedBadgeDefinitions} = require("./badgeSeeder");

/**
 * Send FCM when an in-app notification document is created under
 * users/{userId}/notifications/{notifId}.
 */
exports.onNotificationCreated = functions
    .region("us-central1")
    .firestore.document("users/{userId}/notifications/{notifId}")
    .onCreate(async (snap, context) => {
      try {
        const userId = context.params.userId;
        const notif = snap.data() || {};
        const title = notif.title || "Notification";
        const body = notif.body || "";
        const payloadData = (notif.data && typeof notif.data === "object") ?
        notif.data :
        {};

        // read tokens from users/{userId}/fcmTokens/{token}
        const tokensSnap = await db
            .collection("users")
            .doc(userId)
            .collection("fcmTokens")
            .get();

        const tokens = tokensSnap.docs.map((d) => d.id).filter(Boolean);

        if (tokens.length === 0) {
          console.log("No tokens to send for user", userId);
          return null;
        }

        const message = {
          notification: {title, body},
          data: Object.fromEntries(
              Object.entries(payloadData || {}).map(([k, v]) => [k, String(v)]),
          ),
          tokens,
        };

        const resp = await messaging.sendMulticast(message);
        console.log(`FCM: success=${resp.successCount} failure=${resp.failureCount}`);

        // remove invalid tokens
        const removals = [];
        resp.responses.forEach((r, i) => {
          if (!r.success) {
            const err = r.error;
            if (
              err &&
            (err.code === "messaging/invalid-registration-token" ||
              err.code === "messaging/registration-token-not-registered")
            ) {
              const badToken = tokens[i];
              console.log("Removing invalid token", badToken, "for user", userId);
              removals.push(
                  db.collection("users").doc(userId).collection("fcmTokens").doc(badToken).delete(),
              );
            }
          }
        });

        if (removals.length) {
          await Promise.all(removals);
        }

        return null;
      } catch (err) {
        console.error("onNotificationCreated error", err);
        return null;
      }
    });

// re-export your existing functions
exports.awardStreakBadge = awardStreakBadge;
exports.weeklyParentDigest = weeklyParentDigest;
exports.seedBadgeDefinitions = seedBadgeDefinitions;
