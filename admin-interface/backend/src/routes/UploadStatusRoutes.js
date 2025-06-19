const express = require("express");
const router = express.Router();
const uploadStatusController = require("../controllers/UploadStatusController");

// Update upload-to-cloud status by Admission_no
router.put("/", uploadStatusController.updateUploadStatus);

module.exports = router;
