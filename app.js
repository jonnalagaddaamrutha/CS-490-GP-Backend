import admin from "firebase-admin";
const express = require('express');
require('dotenv').config();
const cors = require('cors');
const mysql = require('mysql2/promise');
const app = express();
const port = 3000;
const salonRoutes = require("./routes/salonRoutes");

import serviceAccount from "./firebase-service-account.json" assert { type: "json" };

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

console.log("✅ Firebase Admin initialized");

app.use(cors());
app.use(express.urlencoded({ extended: true }));
app.use(express.json());


app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});

app.use("/api/films", salonRoutes);
