const { sql, connectToDatabase } = require("../../config/db");

const getAvailableBeds = async (wardNo) => {
    try {
        const pool = await connectToDatabase();

        const result = await pool.request()
            .input("wardNo", sql.Char(3), wardNo)
            .query("SELECT Bed_no FROM Bed WHERE Ward_no = @wardNo AND is_occupied = 0");

        return result.recordset;
    } catch (error) {
        console.error("Error fetching available beds:", error);
        throw error;
    }
};

module.exports = {
    getAvailableBeds,
};
