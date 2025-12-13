const express = require("express");
const admin = require("firebase-admin");

const app = express();
app.use(express.json());

// ✅ Health check route
app.get("/", (req, res) => {
  res.send("FCM SERVER IS RUNNING");
});

// 🔐 Firebase Admin Init (Render compatible)
admin.initializeApp({
  credential: admin.credential.cert(
    JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
  ),
});

const db = admin.firestore();

/**
 * 🔔 Notify Owner API
 * Guard → Node → Owner
 */
app.post("/notify-owner", async (req, res) => {
  try {
    const { ownerId, passId, type } = req.body;

    if (!ownerId || !passId || !type) {
      return res.status(400).json({ error: "Missing parameters" });
    }

    const ownerDoc = await db.collection("users").doc(ownerId).get();
    if (!ownerDoc.exists) {
      return res.status(404).json({ error: "Owner not found" });
    }

    const ownerData = ownerDoc.data();
    if (ownerData.role !== "owner") {
      return res.status(403).json({ error: "User is not an owner" });
    }

    const token = ownerData.fcmToken;
    if (!token) {
      return res.status(400).json({ error: "Owner has no FCM token" });
    }

    await admin.messaging().send({
      token,
      notification: {
        title: "New Entry Approval Required",
        body:
          type === "visitor"
            ? "A visitor is waiting for approval"
            : "A vehicle is waiting for approval",
      },
      data: { type, passId },
      android: { priority: "high" },
    });

    res.json({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ FCM server running on port ${PORT}`);
});
