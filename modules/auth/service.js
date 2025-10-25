const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../../config/database");
const admin = require("../../config/firebaseAdmin");

// =====================
// MANUAL AUTH HELPERS
// =====================

async function findUserByEmail(email) {
  const [rows] = await db.query(
    "SELECT u.*, a.password_hash FROM users u JOIN auth a ON u.user_id = a.user_id WHERE u.email = ?",
    [email]
  );
  return rows[0];
}

async function createUser(full_name, phone, email, role = "customer") {
  const [userResult] = await db.query(
    "INSERT INTO users (full_name, phone, email, user_role) VALUES (?, ?, ?, ?)",
    [full_name, phone, email, role]
  );
  return userResult.insertId;
}

async function createAuthRecord(userId, email, password) {
  const hash = await bcrypt.hash(password, 10);
  await db.query(
    "INSERT INTO auth (user_id, email, password_hash) VALUES (?, ?, ?)",
    [userId, email, hash]
  );
}

async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}

async function updateLoginStats(userId) {
  await db.query(
    "UPDATE auth SET last_login = NOW(), login_count = login_count + 1 WHERE user_id = ?",
    [userId]
  );
}

function generateJwtToken(payload, expiresIn = "2h") {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn });
}

// =====================
// FIREBASE HELPERS
// =====================

async function verifyFirebaseToken(idToken) {
  return await admin.auth().verifyIdToken(idToken);
}

function generateFirebaseJwt(decoded) {
  return jwt.sign(
    {
      uid: decoded.uid,
      email: decoded.email,
      provider: decoded.firebase.sign_in_provider,
    },
    process.env.JWT_SECRET,
    { expiresIn: "1h" }
  );
}

module.exports = {
  findUserByEmail,
  createUser,
  createAuthRecord,
  verifyPassword,
  updateLoginStats,
  generateJwtToken,
  verifyFirebaseToken,
  generateFirebaseJwt,
};
