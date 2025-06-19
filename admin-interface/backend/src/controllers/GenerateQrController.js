const generateQRModel = require("../models/GenerateQrModel");
const { connectToDatabase } = require("../../config/db");

exports.handleGenerateQR = async (req, res) => {
    try {
        const pool = await connectToDatabase();

        const wardNo = req.params.ward_no;
        const { isSingleBed, selectedBedCount } = req.body;

        if (!wardNo) return res.status(400).json({ error: "Ward_no is required" });
        if (!isSingleBed && (selectedBedCount < 2 || selectedBedCount > 20)) {
            return res.status(400).json({ error: "Bed count must be between 2 and 20" });
        }

        const result = await generateQRModel.generateQR(pool, wardNo, isSingleBed, selectedBedCount);
        res.status(201).json(result);

    } catch (error) {
        console.error("❌ Controller Error:", error.message);
        res.status(500).json({ error: error.message });
    }
};
