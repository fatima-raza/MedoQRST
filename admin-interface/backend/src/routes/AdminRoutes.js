const express = require("express");
const adminController = require("../controllers/AdminController");
const router = express.Router();

// Define route for creating a new admin
router.post("/create", adminController.handleCreateAdmin);

// Define route for fetching admins
router.get("/read", adminController.handleGetAllAdmins);

// Define route for fetching specific admin
router.get("/read/:id", adminController.handleGetAdminById);

// define route for updating password
router.post("/change-password", adminController.handleChangeAdminPassword);

// define route for updating password when forgot
router.post("/forgot-password", adminController.handleForgotAdminPasswordReset);

module.exports = router;