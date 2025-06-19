// routes/vitalRoutes.js
const express = require('express');
const router = express.Router();
const vitalsController = require('../controllers/VitalsController');

router.get("/:admissionID", vitalsController.getPatientVitals);

module.exports = router;
