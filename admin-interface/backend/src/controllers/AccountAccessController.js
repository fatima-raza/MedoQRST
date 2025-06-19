const bcrypt = require("bcrypt");
const adminModel = require("../models/AdminModel");

const handleLogin = async (req, res) => {
    try {
        const { username, password } = req.body;

        // Validate required fields
        if (!username || !password) {
            return res.status(400).json({ error: "Username and password are required" });
        }

        // Check if the user exists
        const admin = await adminModel.getAdminByUsername(username);
        if (!admin) {
            return res.status(401).json({ error: "Invalid credentials" });
        }

        // Compare the entered password with the hashed password
        const isPasswordCorrect = await bcrypt.compare(password, admin.Password);
        if (!isPasswordCorrect) {
            return res.status(401).json({ error: "Invalid credentials" });
        }

        // Create a session and store user information in the session
        req.session.userId = admin.UserID;
        req.session.username = admin.User_name;
        console.log("Session created:", req.session);
        console.log("Sending session cookie:", req.sessionID);
        res.on('finish', () => {
            console.log("Set-Cookie header sent:", res.getHeader("Set-Cookie"));
        });

        // Respond with success
        return res.status(200).json({
            message: "Login successful",
            userId: admin.UserID,
            username: admin.User_name
        });
    } catch (error) {
        console.error("Error during login:", error);
        return res.status(500).json({ error: "Internal server error" });
    }
};

const handleLogout = (req, res) => {
    // Destroy the session when the user logs out
    req.session.destroy((err) => {
        if (err) {
            return res.status(500).json({ error: "Failed to log out" });
        }
        res.clearCookie("connect.sid"); // Clear session cookie
        return res.status(200).json({ message: "Logout successful" });
    });
};

module.exports = { handleLogin, handleLogout };
