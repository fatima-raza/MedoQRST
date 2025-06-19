const { connectToDatabase } = require('../../config/db');
const uploadStatusModel = require('../models/UploadStatusModel');

exports.updateUploadStatus = async (req, res) => {
  try {
    const pool = await connectToDatabase();
    const { Admission_no, Uploaded_to_cloud } = req.body;

    console.log(`Received request to update Uploaded_to_cloud for Admission_no: ${Admission_no} to ${Uploaded_to_cloud}`);

    if (!Admission_no) {
      return res.status(400).json({ error: "Admission_no is required." });
    }

    if (typeof Uploaded_to_cloud !== 'boolean') {
      return res.status(400).json({ error: "Uploaded_to_cloud must be a boolean." });
    }

    const result = await uploadStatusModel.updateUploadStatus(pool, Admission_no, Uploaded_to_cloud);

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ message: "No discharge record found to update." });
    }

    res.status(200).json({ message: "Upload status updated successfully." });

  } catch (error) {
    console.error("Error updating upload status:", error.message);
    res.status(500).json({ error: error.message });
  }
};
