const express = require("express");
const router = express.Router();
const bedStatusController = require("../controllers/BedStatusController");

// Update bed occupied status by Bed_no and Ward_no
router.put("/", bedStatusController.updateBedOccupiedStatus);

module.exports = router;
