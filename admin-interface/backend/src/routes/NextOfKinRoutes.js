const express = require("express");
const router = express.Router();
const nextOfKinController = require("../controllers/NextOfKinController");

// Get Next of Kin details by admission ID
router.get("/:admissionID", nextOfKinController.getNextOfKinByAdmissionID);

module.exports = router;
