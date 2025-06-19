// routes/userRoutes.js
const express = require('express');
const router = express.Router();
const userController = require('../controllers/UserController');

// Fetch user details based on admissionID
router.get("/:admissionID", userController.getUserDetails);


module.exports = router;
