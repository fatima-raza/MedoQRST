const express = require("express");
const admissionInfoController = require("../controllers/AdmissionInfoController");
const router = express.Router();

// Route for adding admission info about the patient
router.post("/create", admissionInfoController.handleCreateAdmission);

// Route for fetching specific admission records
router.get("/read/:admissionNo", admissionInfoController.handleGetAdmissionById);

// Route for fetching all admission records
router.get("/read", admissionInfoController.handleGetAllAdmissions);

// Route for updating a specific admission records
router.put("/update/:admissionNo", admissionInfoController.handleUpdateAdmission);

// Route for deleting a specific admission records
router.delete("/delete/:admissionNo", admissionInfoController.handleDeleteAdmission);

module.exports = router;
