const progressModel = require("../models/ProgressModel");
const { connectToDatabase } = require('../../config/db');

exports.getProgressNotesByadmissionID = async (req, res) => {
    try {
        const pool = await connectToDatabase();

        const { admissionID } = req.params;
        console.log(`Received request for Progress of admissionID: ${admissionID}`);

        const admissionIDPattern = /^\d{6}$/;
        if (!admissionIDPattern.test(admissionID)) {
            console.error("Invalid admissionID format.");
            return res.status(400).json({
                error: "admissionID must be exactly 6 digits (e.g., 123456)"
            });
        }

        const result = await progressModel.fetchProgressNotes(pool, admissionID);

        if (!result || result.recordset.length === 0) {
            console.warn(`No progress record found for admissionID: ${admissionID}`);
            return res.status(404).json({ message: "No progress record found for this admissionID." });
        }

        res.json(result.recordset);
    } catch (error) {
        console.error("Error fetching progress details:", error.message);
        res.status(500).json({ error: error.message });
    }
};
