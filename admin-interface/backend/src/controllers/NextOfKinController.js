const nextOfKinModel = require("../models/NextOfKinModel");
const { connectToDatabase } = require("../../config/db"); // <-- use your db setup

exports.getNextOfKinByAdmissionID = async (req, res) => {
    const { admissionID } = req.params;

    if (!admissionID) {
        return res.status(400).json({ message: "Admission ID is required." });
    }

    try {
        const pool = await connectToDatabase();
        const result = await nextOfKinModel.fetchNextOfKinByAdmissionID(pool, admissionID);

        if (!result || result.length === 0) {
            return res.status(404).json({ message: "No Next of Kin record found for the provided Admission ID." });
        }

        res.json({ data: result });
    } catch (error) {
        console.error("❌ Error fetching Next of Kin details:", error.message);
        res.status(500).json({ error: error.message });
    }
};
