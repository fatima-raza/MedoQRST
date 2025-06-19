const express = require("express");
const router = express.Router();
const dischargeController = require("../controllers/DischargeController");

// Get discharge details by patient ID
router.get("/:admissionID", dischargeController.getDischargeDetailsByadmissionID);

module.exports = router;
