const regenerateQRModel = require("../models/RegenerateQrModel");
const { connectToDatabase } = require("../../config/db");

exports.handleRegenerateQR = async (req, res) => {
  try {
    const pool = await connectToDatabase();
    const wardNo = req.params.ward_no;
    const bedNo = req.params.bed_no;

    if (!wardNo || !bedNo) {
      return res.status(400).json({ error: "ward_no and bed_no are required." });
    }

    const result = await regenerateQRModel.regenerateQR(pool, wardNo, bedNo);
    res.status(200).json(result);

  } catch (error) {
    console.error("❌ Regenerate Controller Error:", error.message);
    res.status(500).json({ error: error.message });
  }
};
