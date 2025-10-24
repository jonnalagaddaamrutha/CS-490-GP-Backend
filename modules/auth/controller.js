const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const db = require("../../config/database");
const admin = require("../../config/firebaseAdmin");

// ==========================
// MANUAL SIGNUP
// ==========================
exports.signupManual = async (req, res) => {
  const { full_name, phone, email, password } = req.body;

  if (!full_name || !phone || !email || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    // Check if email already exists
    const [existing] = await db.query("SELECT * FROM users WHERE email = ?", [
      email,
    ]);
    if (existing.length > 0) {
      return res.status(409).json({ error: "Email already registered" });
    }

    // Create user
    const [userResult] = await db.query(
      "INSERT INTO users (full_name, phone, email, user_role) VALUES (?, ?, ?, 'customer')",
      [full_name, phone, email]
    );
    const userId = userResult.insertId;

    // Hash password
    const hash = await bcrypt.hash(password, 10);

    // Create auth record
    await db.query(
      "INSERT INTO auth (user_id, email, password_hash) VALUES (?, ?, ?)",
      [userId, email, hash]
    );

    res.status(201).json({ message: "User registered successfully" });
  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ error: "Server error during signup" });
  }
};

// ==========================
// MANUAL LOGIN
// ==========================
exports.loginManual = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password required" });
  }

  try {
    const [rows] = await db.query(
      "SELECT u.*, a.password_hash FROM users u JOIN auth a ON u.user_id = a.user_id WHERE u.email = ?",
      [email]
    );
    const user = rows[0];
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Verify password
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: "Invalid password" });
    }

    // Update login stats
    await db.query(
      "UPDATE auth SET last_login = NOW(), login_count = login_count + 1 WHERE user_id = ?",
      [user.user_id]
    );

    // Create JWT
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email, role: user.user_role },
      process.env.JWT_SECRET,
      { expiresIn: "2h" }
    );

    res.json({ message: "Login successful", token });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ error: "Server error during login" });
  }
};

// ==========================
// EXISTING FIREBASE LOGIC
// ==========================
exports.verifyFirebase = async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ")
      ? authHeader.split(" ")[1]
      : null;

    if (!idToken)
      return res.status(401).json({ error: "Missing Firebase token" });

    const decoded = await admin.auth().verifyIdToken(idToken);
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
};

// ==========================
// EXISTING LOGOUT + CURRENT USER
// ==========================
exports.getCurrentUser = async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM users WHERE email = ?", [
      req.firebaseUser.email,
    ]);
    res.json({
      firebaseUser: req.firebaseUser,
      customJWT: req.customJwt,
      userProfile: rows[0],
    });
  } catch (error) {
    console.error("Error getting user:", error);
    res.status(500).json({ error: "Database error" });
  }
};

exports.logout = async (req, res) => {
  res.json({ message: "Logged out successfully" });
};
