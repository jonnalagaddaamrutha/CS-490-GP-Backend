// modules/auth/routes.js
const express = require("express");
const router = express.Router();
const authController = require("./controller");
const { authenticateUser } = require("../../middleware/firebaseAuth");
const jwt = require("jsonwebtoken");
const admin = require("../../config/firebaseAdmin"); // ✅ we'll make this next

// Existing routes
router.post("/signup", authController.signup);
router.post("/login", authController.login);
router.get("/me", authenticateUser, authController.getCurrentUser);
router.post("/logout", authenticateUser, authController.logout);

// ✅ New route for Firebase token verification
router.post("/verify-firebase", async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ")
      ? authHeader.split(" ")[1]
      : null;

    if (!idToken)
      return res.status(401).json({ error: "Missing Firebase token" });

    // Verify Firebase token
    const decoded = await admin.auth().verifyIdToken(idToken);

    // Create your custom JWT
    const customJwt = jwt.sign(
      {
        uid: decoded.uid,
        email: decoded.email,
        provider: decoded.firebase.sign_in_provider,
      },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    res.json({ token: customJwt });
  } catch (err) {
    console.error("Firebase verification failed:", err);
    res.status(401).json({ error: "Invalid Firebase token" });
  }
});

module.exports = router;
