const { connectToDatabase, sql } = require("../../config/db");
const prescriptionModel = require("../models/PrescriptionSheetModel");

exports.getPrescriptionSheetByadmissionID = async (req, res) => {
    const { admissionID } = req.params;

    if (!admissionID) {
        return res.status(400).json({ message: "Patient ID is required." });
    }

    try {
        const pool = await connectToDatabase();

        if (!pool) {
            console.error("❌ Database connection is not established.");
            return res.status(500).json({ error: "Database connection not established" });
          
        } console.log(`Received request for Prescription Report of admissionID: ${admissionID}`);

        const result = await prescriptionModel.fetchPrescriptionSheetByadmissionID(pool, admissionID);

          // Print the fetched result to debug
          console.log("Fetched data from prescription model:", result); 

        if (!result || result.length === 0) {
            return res.status(404).json({ message: "No medication records found for this Patient ID." });
        }

        res.json({ data: result });
    } catch (error) {
        console.error("❌ Error fetching prescription sheet data:", error.message);
        res.status(500).json({ error: error.message });
    }
};
