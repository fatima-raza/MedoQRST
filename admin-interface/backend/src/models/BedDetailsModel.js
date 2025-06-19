exports.getBedDetails = async (pool) => {
    try {
        const result = await pool.request().query(`
            SELECT Bed.Bed_no, Ward.Ward_no, Bed.QRcode, Ward.Ward_name, Bed.is_occupied
            FROM Bed
            INNER JOIN Ward ON Bed.Ward_no = Ward.Ward_no;
        `);

        return result.recordset; // Use .recordset with mssql
    } catch (error) {
        console.error("Error in bedDetailsModel:", error.message);
        throw error;
    }
};
