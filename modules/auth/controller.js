const jwt = require("jsonwebtoken");
const db = require("../../config/database");

exports.signup = async (req, res) => {
  res.json({ message: "Signup not used — handled by Firebase OAuth" });
};

exports.login = async (req, res) => {
  res.json({ message: "Login handled via Firebase OAuth" });
};

exports.getCurrentUser = async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM users WHERE email = ?", [
      req.firebaseUser.email,
    ]);

    res.json({
      firebaseUser: req.firebaseUser,
      customJWT: req.customJwt,
      userProfile: rows[0] || null,
    });
  } catch (error) {
    console.error("Database error:", error);
    res.status(500).json({ error: "Database query failed" });
  }
};

exports.logout = async (req, res) => {
  res.json({ message: "Logged out successfully" });
};
