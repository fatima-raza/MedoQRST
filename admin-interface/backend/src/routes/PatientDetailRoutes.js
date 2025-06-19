const express = require('express');
const router = express.Router();

const patientDetailController = require('../controllers/PatientDetailController');

// Get patient details by admissionID
router.get("/:admissionID", patientDetailController.getPatientDetails);


module.exports = router;
