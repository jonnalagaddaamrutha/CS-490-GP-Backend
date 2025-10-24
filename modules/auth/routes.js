// modules/auth/routes.js
const express = require("express");
const router = express.Router();
const authController = require("./controller");
const { authenticateUser } = require("../../middleware/firebaseAuth");
const { verifyCustomJwt } = require("../../middleware/verifyCustomJwt");
const jwt = require("jsonwebtoken");
const admin = require("../../config/firebaseAdmin");

// =============================
// MANUAL EMAIL + PASSWORD AUTH
// =============================

router.post("/signup", authController.signupManual);
router.post("/login", authController.loginManual);

router.get("/profile", verifyCustomJwt, (req, res) => {
  res.json({
    message: "Manual JWT verified successfully",
    user: req.user,
  });
});

// =============================
// FIREBASE OAUTH AUTHENTICATION
// =============================

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

    // Create your own JWT
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

// Firebase-protected routes
router.get("/me", authenticateUser, authController.getCurrentUser);
router.post("/logout", authenticateUser, authController.logout);

module.exports = router;
