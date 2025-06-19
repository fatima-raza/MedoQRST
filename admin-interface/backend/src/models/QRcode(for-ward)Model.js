const { sql, connectToDatabase } = require("../../config/db");

// Function to get all wards from the database
const getAllQRcodes = async () => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .query("SELECT * FROM QRcode");

        return result.recordset;
    } catch (error) {
        console.error("Error fetching QRcodes:", error);
        throw error;
    }
};

// Function to create a new QR code
const createQRcode = async (transaction) => {
    try {
        const request = transaction.request();
        const result = await request
            .input("date_generated", sql.Date, new Date())
            .input("assigned_to", sql.NVarChar(50), 'Ward')
            .query(`
                DECLARE @date DATE = @date_generated;
                DECLARE @assigned NVARCHAR(50) = @assigned_to;

                INSERT INTO QRcode (Date_generated, Assigned_to)
                VALUES (@date, @assigned);

                SELECT TOP 1 qrID
                FROM QRcode
                WHERE Date_generated = @date AND Assigned_to = @assigned
                ORDER BY qrID DESC;
            `);

        console.log("QR INSERT result:", result.recordset);
        return result.recordset[0];
    } catch (error) {
        console.error("Error creating QR code:", error);
        throw error;
    }
};

const invalidateOldWardQR = async (wardName, transaction) => {
    try {
        const request = transaction.request();
        const result = await request
            .input("wardName", sql.NVarChar(100), wardName)
            .query(`
                UPDATE QRcode
                SET [Status] = 'Inactive'
                WHERE qrID = (
                    SELECT QRcode FROM Ward WHERE Ward_name = @wardName
                );
            `);

        return result.rowsAffected[0] > 0;
    } catch (error) {
        console.error("Error invalidating old QR:", error);
        throw error;
    }
};



module.exports = {getAllQRcodes, createQRcode, invalidateOldWardQR}