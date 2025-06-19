const dischargeModel = require("../models/DischargeModel");
const { connectToDatabase, sql } = require("../../config/db"); // <-- use your db setup

exports.getDischargeDetailsByadmissionID = async (req, res) => {
    const { admissionID } = req.params;

    if (!admissionID) {
        return res.status(400).json({ message: "Patient ID is required." });
    }

    try {
        const pool = await connectToDatabase();
        const result = await dischargeModel.fetchDischargeDetailsByadmissionID(pool, admissionID);

        if (!result || result.length === 0) {
            return res.status(404).json({ message: "No records found for the provided Admission No" });
        }

        res.json({ data: result });
    } catch (error) {
        console.error("❌ Error fetching discharge details:", error.message);
        res.status(500).json({ error: error.message });
    }
};
