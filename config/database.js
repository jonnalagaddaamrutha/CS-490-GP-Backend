const mysql = require('mysql2/promise');
require('dotenv').config();
const pool = mysql.createPool({
    user: process.env.DB_USER, 
    password: process.env.DB_PASSWORD, 
    host:process.env.DB_HOST,
    port:process.env.DB_PORT || 3306,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

async function query(sql, params) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

module.exports = { query };