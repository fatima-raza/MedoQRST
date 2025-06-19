const express = require("express");
const router = express.Router();
const drugController = require("../controllers/DrugSheetController");

router.get("/:admissionID", drugController.getDrugSheetByAdmissionID);

module.exports = router;
