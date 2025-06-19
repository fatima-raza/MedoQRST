const express = require("express");
const emergencyContactController = require("../controllers/EmergencyContactController");
const router = express.Router();

// Route to create Emergency contact details
router.post("/create", emergencyContactController.handleEmergencyContact);

// Route for fetching specific admission
router.get("/read/:admissionNo", emergencyContactController.handleGetEmergencyContactById);

// Route for fetching specific admission records
router.get("/read", emergencyContactController.handleGetAllEmergencyContacts);

module.exports = router;
