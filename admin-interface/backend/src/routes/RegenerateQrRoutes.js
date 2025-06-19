const express = require("express");
const router = express.Router();
const regenerateQRController = require('../controllers/RegenerateQrController');

router.post('/:ward_no/:bed_no', regenerateQRController.handleRegenerateQR);

module.exports = router;
