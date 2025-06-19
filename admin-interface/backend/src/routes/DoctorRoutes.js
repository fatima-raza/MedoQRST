const express = require("express");
const doctorController = require("../controllers/DoctorController");
const router = express.Router();

// Define route for creating a new doctor
router.post("/create", doctorController.handleCreateDoctor);

// Define route for fetching doctors
router.get("/read", doctorController.handleGetAllDoctors);

// Define route for fetching specific doctors
router.get("/read/:id", doctorController.handleGetDoctorById);

module.exports = router;