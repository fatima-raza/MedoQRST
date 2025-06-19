const express = require("express");
const router = express.Router();
const resendPwdSetup = require("../controllers/ResendPwdSetupController");

router.get("/resend-pwd-setup", resendPwdSetup.handleResendPwdSetupLink);

module.exports = router;
