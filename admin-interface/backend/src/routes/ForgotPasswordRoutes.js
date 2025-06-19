const express = require("express");
const forgetPasswordController = require("../controllers/ForgotPasswordController");
const router = express.Router();

// route to verify reset password token
router.get("/verify-reset-token", forgetPasswordController.handleVerifyResetToken);

// Set new password
router.post("/reset-password", forgetPasswordController.handleResetPassword);

module.exports = router;