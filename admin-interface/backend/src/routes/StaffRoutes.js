const express = require('express');
const staffController = require('../controllers/StaffController');
const router = express.Router();

// route for fetching a Userid by Token
router.post('/get-staff-by-token', staffController.handleGetStaffIdByToken);

module.exports = router;
