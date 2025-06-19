const { connectToDatabase } = require('../../config/db');
const disposalModel = require('../models/DisposalModel');

exports.updateDisposalStatus = async (req, res) => {
    try {
        const pool = await connectToDatabase();
        const { admissionID } = req.params;
        const { Disposal_status } = req.body;

        console.log(`Received request to update Disposal_status for admissionID: ${admissionID} with status: ${Disposal_status}`);

        // Validate admission ID
        const admissionIDPattern = /^\d{6}$/;
        if (!admissionIDPattern.test(admissionID)) {
            console.error("Invalid admissionID format.");
            return res.status(400).json({
                error: "AdmissionID must be exactly 6 digits (e.g., 123456)"
            });
        }

        // Validate Disposal_status
        if (!Disposal_status) {
            return res.status(400).json({ error: "Disposal_status is required in the request body." });
        }

        // Use the model method to update
        const result = await disposalModel.updateDisposalStatus(pool, admissionID, Disposal_status);

        if (result.rowsAffected[0] === 0) {
            console.warn(`No patient found with admissionID: ${admissionID}`);
            return res.status(404).json({ message: "No patient found to update." });
        }

        console.log(`Disposal_status updated successfully for admissionID: ${admissionID}`);
        res.status(200).json({ message: "Disposal status updated successfully." });

    } catch (error) {
        console.error("Error updating disposal status:", error.message);
        res.status(500).json({ error: error.message });
    }
};
