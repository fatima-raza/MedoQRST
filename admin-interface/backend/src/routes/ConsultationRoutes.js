const express = require("express");
const router = express.Router();
const consultationController = require("../controllers/ConsultationController");

// Route to get consultation sheet by patientID
router.get("/:admissionID", consultationController.getConsultationByadmissionID);

module.exports = router;
