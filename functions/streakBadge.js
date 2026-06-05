const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

/**
 * Triggered when a member’s plan progress updates.
 * Awards a streak badge if all days are completed.
 */
exports.awardStreakBadge = onDocumentUpdated(
    "plans/{planId}/members/{userId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      const {planId, userId} = event.params;

      // Count completed days
      const daysCompleted = Object.keys(after)
          .filter(
              (key) => key.endsWith("Complete") && after[key] === true,
          )
          .length;

      const planSnap = await admin.firestore()
          .collection("plans")
          .doc(planId)
          .get();
      if (!planSnap.exists) return;
      const plan = planSnap.data();

      // Award badge if plan fully completed
      if (daysCompleted === plan.days && !before.completedAt) {
        const badgeId = `${planId}Complete`;

        await admin.firestore()
            .collection("users")
            .doc(userId)
            .update({
              badges: admin.firestore.FieldValue.arrayUnion(badgeId),
              streakCount: admin.firestore.FieldValue.increment(1),
              completedAt: new Date().toISOString(),
            });

        console.log(`Awarded badge ${badgeId} to user ${userId}`);
      }
    },
);
