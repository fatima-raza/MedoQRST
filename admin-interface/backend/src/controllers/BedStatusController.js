const { connectToDatabase } = require('../../config/db');
const bedStatusModel= require('../models/BedStatusModel');

exports.updateBedOccupiedStatus = async (req, res) => {
    try {
        const pool = await connectToDatabase();
        const { Bed_no, Ward_no, is_occupied } = req.body;

        console.log(`Received request to update is_occupied for Bed_no: ${Bed_no}, Ward_no: ${Ward_no} to ${is_occupied}`);

        // Validation
        if (!Bed_no || !Ward_no) {
            return res.status(400).json({ error: "Both Bed_no and Ward_no are required." });
        }

        if (typeof is_occupied !== 'number' || (is_occupied !== 0 && is_occupied !== 1)) {
            return res.status(400).json({ error: "is_occupied must be either 0 or 1." });
        }

        const result = await bedStatusModel.updateBedOccupiedStatus(pool, Bed_no, Ward_no, is_occupied);

        if (result.rowsAffected[0] === 0) {
            console.warn(`No bed found with Bed_no: ${Bed_no} and Ward_no: ${Ward_no}`);
            return res.status(404).json({ message: "No bed found to update." });
        }

        console.log(`is_occupied updated successfully for Bed_no: ${Bed_no}, Ward_no: ${Ward_no}`);
        res.status(200).json({ message: "Bed occupancy status updated successfully." });

    } catch (error) {
        console.error("Error updating bed occupancy status:", error.message);
        res.status(500).json({ error: error.message });
    }
};
