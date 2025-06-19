const { sql } = require('../../config/db');

exports.updateBedOccupiedStatus = async (pool, bedNo, wardNo, isOccupied) => {
    try {
        const result = await pool.request()
            .input("Bed_no", sql.Int, bedNo)
            .input("Ward_no", sql.Char(10), wardNo)
            .input("is_occupied", sql.Bit, isOccupied)
            .query(`
                UPDATE Bed
                SET is_occupied = @is_occupied
                WHERE Bed_no = @Bed_no AND Ward_no = @Ward_no AND is_occupied = 1
            `);

        return result;
    } catch (error) {
        console.error("Error in updateBedOccupiedStatus:", error.message);
        throw error;
    }
};
