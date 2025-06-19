const express = require('express');
const wardController = require('../controllers/WardController');
const router = express.Router();

// route for fetching all wards
router.get('/read', wardController.handleGetAllWards);

// route for creating a ward
router.post('/create', wardController.handleCreateWard);

// route for creating a ward
router.post('/update', wardController.handleRegenerateWardQR);

// Get all wards
router.get("/", wardController.getAllWards);

module.exports = router;

