const bedDetailsModel = require('../models/BedDetailsModel');
const { connectToDatabase } = require('../../config/db'); // your mssql-based DB connection

exports.getBedDetails = async (req, res) => {
    try {
        // Use your DB connection function instead of app.locals
        const pool = await connectToDatabase();

        // Call the model with dbConnection
        const bedDetails = await bedDetailsModel.getBedDetails(pool);

        if (!bedDetails || bedDetails.length === 0) {
            console.log("❌ No records found in database.");
            return res.status(404).json({ message: "No bed records found." });
        }

        console.log("✅ Bed details fetched successfully:", bedDetails);
        res.status(200).json({ data: bedDetails });

    } catch (error) {
        console.error("❌ Error in controller:", error.message);
        res.status(500).json({ error: error.message });
    }
};
