const express = require("express");
const bedController = require("../controllers/BedController");
const router = express.Router();

// fetch all available beds for the ward number
router.get("/:wardNo/available-beds", bedController.handleGetAvailableBeds);

module.exports = router;
