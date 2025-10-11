const mysql = require('mysql2/promise');
require('dotenv').config();
const pool = mysql.createPool({
    user: process.env.user, 
    password: process.env.password, 
    host:process.env.host,
    port:process.env.port,
    database: process.env.database,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

async function query(sql, params) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

module.exports = { query };