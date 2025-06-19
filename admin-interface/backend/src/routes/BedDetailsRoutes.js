const express = require('express');
const router = express.Router();
const bedDetailsController = require('../controllers/BedDetailsController');

// Fetching all bed details along with ward names
router.get("/", bedDetailsController.getBedDetails);

module.exports = router;



