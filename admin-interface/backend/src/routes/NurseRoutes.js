const express = require("express");
const nurseController = require("../controllers/NurseController");
const router = express.Router();

// Define route for creating a new nurse
router.post("/create", nurseController.handleCreateNurse);

// Define route for fetching nurses
router.get("/read", nurseController.handleGetAllNurses);

// Define route for fetching specific nurses
router.get("/read/:id", nurseController.handleGetNurseById);

module.exports = router;