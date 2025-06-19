const express = require("express");
const router = express.Router();
const generateQRController = require('../controllers/GenerateQrController');

router.post('/:ward_no', generateQRController.handleGenerateQR);


module.exports = router;
