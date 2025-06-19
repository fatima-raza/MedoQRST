const express = require("express");
const patientInfoController = require("../controllers/PatientInfoController");
const router = express.Router();

// Route for registering a patient (POST)
router.post("/create", patientInfoController.handleCreatePatient);

// Route for fetching patient by ID (GET)
router.get("/read/:id", patientInfoController.handleGetPatientById);

// Route for fetching all patient records
router.get("/read", patientInfoController.handleGetAllPatients);

// Route for updating a patient record
router.put("/update/:id", patientInfoController.handleUpdatePatient);

// Route for deleting a patient record
router.delete("/delete/:id", patientInfoController.handleDeletePatient);

// Route to search patient by ID or CNIC
router.get("/search/:identifier", patientInfoController.handleSearchPatient);

module.exports = router;
