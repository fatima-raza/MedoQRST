const patientDetailModel = require('../models/PatientDetailModel');
const { connectToDatabase } = require('../../config/db');

exports.getPatientDetails = async (req, res) => {
    try {
        const pool = await connectToDatabase(); // Consistent pooled connection

        const { admissionID } = req.params;
        console.log(`Received request for admissionID: ${admissionID}`);

        if (!admissionID) {
            console.error("admissionID is missing in the request.");
            return res.status(400).json({ error: "admissionID is required" });
        }

        const result = await patientDetailModel.fetchPatientDetails(pool, admissionID);

        if (!result || result.recordset.length === 0) {
            console.warn(`No record found for admissionID: ${admissionID}`);
            return res.status(404).json({ message: "No record found for this admissionID." });
        }

        console.log(`Retrieved record for admissionID: ${admissionID}`, result.recordset[0]);
        res.status(200).json(result.recordset[0]);

    } catch (error) {
        console.error("Error fetching patient records:", error.message);
        res.status(500).json({ error: error.message });
    }
};
