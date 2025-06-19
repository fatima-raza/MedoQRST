const express = require("express");
const router = express.Router();
const staffModel = require("../models/StaffModel");

const handleGetStaffIdByToken = async (req, res) => {
    const { token } = req.body;
    if (!token) {
        return res.status(400).json({ error: "Token is required" });
    }

    try {
        const userId = await staffModel.getStaffIdByToken(token);

        if (!userId) {
            return res.status(404).json({ error: "No user found for this token" });
        }

        res.status(200).json({ userId });
    } catch (error) {
        console.error("Error fetching user ID from token:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }

};

module.exports = {handleGetStaffIdByToken};
