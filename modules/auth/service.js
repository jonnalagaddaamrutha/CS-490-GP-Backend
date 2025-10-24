const axios = require("axios"); // Promise-based HTTP client, Make http requests from node.js
const db = require('../../config/database');

const firebaseSignIn = async (email, password) => {
    try {
        //const req.param
        const fbResponse = await axios.post(
            `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_API_KEY}`,
            { email: email, password: password, returnSecureToken: true }
        );

        const { idToken, refreshToken, localId } = fbResponse.data;

        try {
            const rows = await db.query(`SELECT * FROM salon_platform_fbase.users WHERE user_id=?`, [localId]);
            console.log(rows)
            const user = rows && rows.length ? rows[0] : null;
            return { idToken, refreshToken, user };
        }
        catch (error) {
            console.error('Failed to fetch staff for the salon', error);
            throw error;
        }
    }
    catch (err) {
        // Pass through Firebase-specific error message when available
        const fbErrMsg = err && err.response && err.response.data && err.response.data.error && err.response.data.error.message;
        console.error('Failed to reach Firebase signInWithPassword:', fbErrMsg || err.message || err);
        if (fbErrMsg) throw new Error(fbErrMsg);
        throw err;
    }
}

const firebaseSignUp = async (full_name, phone, userEmail, passWord, role) => {
    try {
        //const req.param
        const fbResponse = await axios.post(
            `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${process.env.FIREBASE_API_KEY}`,
            { email: userEmail, password: passWord, returnSecureToken: true }
        );
        console.log(fbResponse.data)

        const { idToken, email, refreshToken, expiresIn, localId } = fbResponse.data;

        try {
            const rows = await db.query(`INSERT INTO salon_platform_fbase.users 
                                        (user_id, full_name, phone, email, user_role)
                                        VALUES (?,?,?,?,?)`, [localId, full_name, phone,email,role]);
            const users = await db.query('SELECT * FROM salon_platform_fbase.users WHERE user_id = ?', [localId])
            const user = users && users.length ? users[0] : null;
            return { message: "Success",user:{ uid:localId, refreshToken, expiresIn, user }};
        }
        catch (error) {
            console.error('Failed to fetch staff for the salon', error);
            throw error;
        }
    }
    catch (err) {
        // Pass through Firebase-specific error message when available
        const fbErrMsg = err && err.response && err.response.data && err.response.data.error && err.response.data.error.message;
        console.error('Failed to reach Firebase signInWithPassword:', fbErrMsg || err.message || err);
        if (fbErrMsg) throw new Error(fbErrMsg);
        throw err;
    }
}

module.exports = { firebaseSignIn, firebaseSignUp }