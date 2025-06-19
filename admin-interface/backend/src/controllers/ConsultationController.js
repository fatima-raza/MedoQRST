const consultationModel = require("../models/ConsultationModel");
const { connectToDatabase } = require("../../config/db");

exports.getConsultationByadmissionID = async (req, res) => {
    const { admissionID } = req.params;

    const admissionIDPattern = /^\d{6}$/;
    if (!admissionIDPattern.test(admissionID)) {
        console.error("❌ Invalid admissionID format.");
        return res.status(400).json({ error: "admissionID must be exactly 6 digits (e.g., 123456) " });
    }

    try {
        const pool = await connectToDatabase();

        const result = await consultationModel.fetchConsultationByadmissionID(pool, admissionID);

        if (!result || result.length === 0) {
            console.warn(`⚠️ No consultation records found for admissionID: ${admissionID}`);
            return res.status(404).json({ message: "No consultation records found for this Patient ID." });
        }

        res.json({ data: result });
    } catch (error) {
        console.error("❌ Error fetching consultation sheet:", error.message);
        res.status(500).json({ error: error.message });
    }
};
