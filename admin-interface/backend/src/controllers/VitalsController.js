const vitalsModel = require('../models/VitalsModel');
const { connectToDatabase } = require('../../config/db');

exports.getPatientVitals = async (req, res) => {
    try {
        const pool = await connectToDatabase();

        const { admissionID } = req.params;
        console.log(`Received request for vitals of Admission ID: ${admissionID}`);

        if (!admissionID) {
            return res.status(400).json({ message: "Admission ID is required." });
        }

        const result = await vitalsModel.fetchVitals(pool, admissionID);
    
          // Debug line to inspect the raw result from the database
    console.debug("Raw result from database:", result);

        if (!result || result.recordset.length === 0) {
            console.warn(`No vitals found for Admission ID: ${admissionID}`);
            return res.status(404).json({ message: "No vitals found for the provided Admission ID." });
        }

        res.status(200).json({ data: result.recordset });
    } catch (error) {
        console.error("Error fetching patient vitals:", error.message);
        res.status(500).json({ error: error.message });
    }
};
