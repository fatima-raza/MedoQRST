const { connectToDatabase, sql } = require("../../config/db");
const drugModel = require("../models/DrugSheetModel");

exports.getDrugSheetByAdmissionID = async (req, res) => {
    const { admissionID } = req.params;

    if (!admissionID) {
        return res.status(400).json({ message: "Admission ID is required." });
    }

    try {
        const pool = await connectToDatabase();

        if (!pool) {
            console.error("❌ Database connection is not established.");
            return res.status(500).json({ error: "Database connection not established" });
        }

        console.log(`📥 Received request for Drug Sheet of admissionID: ${admissionID}`);

        const result = await drugModel.fetchDrugSheetByAdmissionID(pool, admissionID);

        console.log("✅ Fetched drug sheet data:", result);

        if (!result || result.length === 0) {
            return res.status(404).json({ message: "No medication records found for this Admission ID." });
        }

        res.json({ data: result });
    } catch (error) {
        console.error("❌ Error fetching drug sheet data:", error.message);
        res.status(500).json({ error: error.message });
    }
};
