const authService = require("./service");

// ==========================
// MANUAL SIGNUP
// ==========================
exports.signupManual = async (req, res) => {
  const { full_name, phone, email, password } = req.body;

  if (!full_name || !phone || !email || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    const existingUser = await authService.findUserByEmail(email);
    if (existingUser)
      return res.status(409).json({ error: "Email already registered" });

    const userId = await authService.createUser(full_name, phone, email);
    await authService.createAuthRecord(userId, email, password);

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
  if (!email || !password)
    return res.status(400).json({ error: "Email and password required" });

  try {
    const user = await authService.findUserByEmail(email);
    if (!user) return res.status(404).json({ error: "User not found" });

    const valid = await authService.verifyPassword(
      password,
      user.password_hash
    );
    if (!valid) return res.status(401).json({ error: "Invalid password" });

    await authService.updateLoginStats(user.user_id);
    const token = authService.generateJwtToken({
      user_id: user.user_id,
      email: user.email,
      role: user.user_role,
    });

    res.json({ message: "Login successful", token });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ error: "Server error during login" });
  }
};

// ==========================
// FIREBASE LOGIC
// ==========================
exports.verifyFirebase = async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ")
      ? authHeader.split(" ")[1]
      : null;

    if (!idToken)
      return res.status(401).json({ error: "Missing Firebase token" });

    const decoded = await authService.verifyFirebaseToken(idToken);
    const customJwt = authService.generateFirebaseJwt(decoded);

    res.json({ token: customJwt });
  } catch (err) {
    console.error("Firebase verification failed:", err);
    res.status(401).json({ error: "Invalid Firebase token" });
  }
};

// ==========================
// CURRENT USER + LOGOUT
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
