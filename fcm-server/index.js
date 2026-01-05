const express = require("express");
const admin = require("firebase-admin");

const app = express();
app.use(express.json());

/**
 * 🔐 FIREBASE ADMIN INITIALIZATION
 * (Use ONE method only – file based OR env based)
 */

// ✅ OPTION A: FILE BASED (LOCAL / SIMPLE)
// Make sure serviceAccountKey.json exists in this folder
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * ✅ HEALTH CHECK
 */
app.get("/", (req, res) => {
  res.send("✅ FCM SERVER IS RUNNING");
});

/**
 * 🔔 NOTIFY OWNER API (MULTI-OWNER)
 * Guard → Node → ALL Owners
 * DATA-ONLY FCM (required for background + killed)
 */
app.post("/notify-owner", async (req, res) => {
  try {
    const { passId, type } = req.body;

    if (!passId || !type) {
      return res.status(400).json({ error: "Missing parameters" });
    }

    // 🔎 Fetch ALL owners
    const ownersSnap = await db
      .collection("users")
      .where("role", "==", "owner")
      .get();

    if (ownersSnap.empty) {
      return res.status(404).json({ error: "No owners found" });
    }

    const messages = [];

    ownersSnap.forEach((doc) => {
      const data = doc.data();

      if (!data.fcmToken) return;

      messages.push({
        token: data.fcmToken,
        data: {
          title: "New Entry Approval Required",
          body:
            type === "visitor"
              ? "A visitor is waiting for approval"
              : "A vehicle is waiting for approval",
          type,
          passId,
        },
        android: {
          priority: "high",
        },
      });
    });

    if (messages.length === 0) {
      return res.status(400).json({ error: "No valid FCM tokens" });
    }

    // 🔔 SEND TO ALL OWNERS
    await admin.messaging().sendEach(messages);

    res.json({
      success: true,
      sent: messages.length,
    });
  } catch (error) {
    console.error("❌ FCM ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * 🚀 START SERVER
 */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ FCM server running on port ${PORT}`);
});
