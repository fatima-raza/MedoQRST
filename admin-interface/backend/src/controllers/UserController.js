const userModel = require('../models/UserModel');
const { connectToDatabase } = require('../../config/db');

exports.getUserDetails = async (req, res) => {
    try {
        const pool = await connectToDatabase();

        const { admissionID } = req.params;
        console.log(`Received request for admissionID: ${admissionID}`);

      // Validate admissionID format (six digits)
const admissionIDPattern = /^\d{6}$/;
if (!admissionIDPattern.test(admissionID)) {
    console.error("Invalid admissionID format.");
    return res.status(400).json({
        error: "admissionID must be exactly 6 digits (e.g., 123456)"
    });
}


        const result = await userModel.fetchUserDetails(pool, admissionID);

        if (!result || result.recordset.length === 0) {
            console.warn(`No user found for admissionID: ${admissionID}`);
            return res.status(404).json({ message: "No user found for this admissionID." });
        }

        res.json(result.recordset[0]); // Send the first matched user
    } catch (error) {
        console.error("Error fetching user details:", error.message);
        res.status(500).json({ error: error.message });
    }
};
