const forgetPasswordModel = require("../models/ForgotPasswordModel");
const bcrypt = require("bcryptjs");

const handleVerifyResetToken = async (req, res) => {
    const token = req.query.token;

    if (!token) {
        return res.status(400).json({
            status: "invalid",
            error: "Token is required."
        });
    }

    try {
        const user = await forgetPasswordModel.getUserByResetToken(token);

        if (!user) {
            return res.status(400).json({
                status: "invalid",
                error: "Invalid or expired token."
            });
        }

        const { UserID, Reset_token_expiry } = user;

        if (new Date(Reset_token_expiry) < new Date()) {
            return res.status(400).json({
                status: "invalid",
                error: "Token has expired."
            });
        }

        return res.status(200).json({
            status: "valid",
            message: "Token is valid."
        });

    } catch (err) {
        console.error("Token verification failed:", err);
        res.status(500).json({ error: "Internal server error." });
    }
};

const handleResetPassword = async (req, res) => {
    const token = req.query.token;  // Extract from URL instead of body
    const { newPassword } = req.body;

    console.log("Token received in reset-password:", token);

    if (!token || !newPassword) {
        return res.status(400).json({ error: "Token and new password are required." });
    }

    try {
        const user = await forgetPasswordModel.getUserByResetToken(token);
        if (!user) {
            return res.status(400).json({ error: "Invalid or expired token." });
        }

        const { UserID } = user;

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await forgetPasswordModel.updatePasswordByUserId(UserID, hashedPassword);
        res.status(200).json({ message: "Password reset successfully." });

    } catch (err) {
        console.error("Password reset failed:", err);
        res.status(500).json({ error: "Internal server error." });
    }
};

module.exports = {handleVerifyResetToken, handleResetPassword}
