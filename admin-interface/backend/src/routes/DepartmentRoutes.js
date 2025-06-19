const express = require('express');
const departmentController = require('../controllers/DepartmentController');
const router = express.Router();

// route for fetching all wards
router.get('/read', departmentController.handleGetAllDepartments);

module.exports = router;
