const express = require('express');
const qrcodeController = require('../controllers/QRcode(for-ward)Controller');
const router = express.Router();

// route for fetching all wards
router.get('/read', qrcodeController.handleGetAllQRcodes);

router.post('/create', qrcodeController.handleCreateQRcode);

module.exports = router;
