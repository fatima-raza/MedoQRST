const express = require("express");
const loginController = require("../controllers/AccountAccessController");
const router = express.Router();

// Route to handle login
router.post("/login", loginController.handleLogin);

// Route to handle logout
router.post("/logout", loginController.handleLogout);

module.exports = router;
