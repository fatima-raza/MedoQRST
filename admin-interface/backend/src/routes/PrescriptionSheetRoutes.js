const express = require("express");
const router = express.Router();
const prescriptionController = require("../controllers/PrescriptionSheetController");

router.get("/:admissionID", prescriptionController.getPrescriptionSheetByadmissionID);

module.exports = router;
