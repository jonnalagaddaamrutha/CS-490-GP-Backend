const express = require('express');
const router = express.Router();
const authController = require('./controller');
const { authenticateUser } = require('../../middleware/firebaseAuth');

router.post('/signup', authController.signup);
router.post('/login', authController.login);

router.get('/me', authenticateUser, authController.getCurrentUser);
router.post('/logout', authenticateUser, authController.logout);

module.exports = router;