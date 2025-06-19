const setPasswordModel = require("../models/SetPasswordModel");

const handleVerifyToken = async (req, res) => {
    const token = req.query.token;

    if (!token) {
        console.log("No token received.");
        return res.status(400).json({ error: "Token is required" });
    }

    try {
        console.log("Received token:", token);
        const { valid, userId } = await setPasswordModel.verifyToken(token);

        if (!valid) {
            return res.status(400).json({ status: "invalid", error: "Invalid or expired token." });
        }

        console.log("User ID found:", userId);

        // Check if the password is already set
        const passwordExists = await setPasswordModel.isPasswordSet(userId);
        console.log("Password already set:", passwordExists);

        if (passwordExists) {
            return res.json({ status: "already_set", message: "Password has already been set." });
        } else {
            return res.json({ status: "valid", message: "Token is valid, proceed with password setup." });
        }
    } catch (error) {
        console.error("Error during token verification:", error);
        return res.status(500).json({ error: "Server error during token verification." });
    }
};


const handleSetPassword = async (req, res) => {
    const token = req.query.token;  // Extract from URL instead of body
    const { password } = req.body;

    console.log("Received token from URL:", token);

    if (!token || !password) {
        return res.status(400).json({ error: "Token and new password are required." });
    }

    try {
        const result = await setPasswordModel.setPassword(token, password);

        if (!result.success) {
            return res.status(400).json({ error: result.error });
        }

        res.status(200).json({ message: "Password has been set successfully. You can now log in." });
    } catch (error) {
        res.status(500).json({ error: "Internal server error.", details: error.message });
    }
};

module.exports = { handleSetPassword, handleVerifyToken };
