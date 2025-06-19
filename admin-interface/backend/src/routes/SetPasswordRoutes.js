const express = require("express");
const router = express.Router();
const passwordSetupController = require("../controllers/SetPasswordController");

router.post("/set-password", passwordSetupController.handleSetPassword);

router.get("/verify-token", passwordSetupController.handleVerifyToken);

module.exports = router;
