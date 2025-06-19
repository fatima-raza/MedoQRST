const express = require("express");
const router = express.Router();
const disposalController = require("../controllers/DisposalController");


// Update disposal status by admission ID
router.put("/:admissionID", disposalController.updateDisposalStatus);


module.exports = router;

