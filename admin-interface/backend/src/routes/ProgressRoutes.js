const express = require("express");
const router = express.Router();
const progressController = require("../controllers/ProgressController");

// Get progress notes by patient ID
router.get("/:admissionID", progressController.getProgressNotesByadmissionID);

module.exports = router;
