const { sql, connectToDatabase } = require("../../config/db");

//
const fetchAllWards = async (pool) => {
    try {
        const result = await pool.request().query("SELECT * FROM Ward;");
        return result.recordset;
    } catch (error) {
        console.error("Error in fetchAllWards:", error.message);
        throw error;
    }
};

// Function to get all wards from the database
const getAllWards = async () => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .query("SELECT Ward_no, Ward_name FROM Ward");

        return result.recordset;
    } catch (error) {
        console.error("Error fetching wards:", error);
        throw error;
    }
};

const createWard = async (wardName, qrID, transaction) => {
    try {
        const request = transaction.request();
        const result = await request
            .input("wardName", sql.NVarChar(100), wardName)
            .input("qrID", sql.Int, qrID)
            .query(`
                DECLARE @name NVARCHAR(100) = @wardName;
                DECLARE @qr INT = @qrID;

                INSERT INTO Ward (Ward_name, QRcode)
                VALUES (@name, @qr);

                SELECT TOP 1 Ward_no
                FROM Ward
                WHERE Ward_name = @name AND QRcode = @qr
                ORDER BY Ward_no DESC;
            `);

        return result.recordset[0];

    } catch (error) {
        console.error("Error creating ward:", error);
        throw error;
    }
};

const updateWardQR = async (wardName, newQRID, transaction) => {
    try {
        const request = transaction.request();
        const result = await request
            .input("wardName", sql.NVarChar(100), wardName)
            .input("newQRID", sql.Int, newQRID)
            .query(`
                DECLARE @name NVARCHAR(100) = @wardName;
                DECLARE @qr INT = @newQRID;

                UPDATE Ward
                SET QRcode = @qr
                WHERE Ward_name = @name;

                SELECT TOP 1 Ward_no
                FROM Ward
                WHERE Ward_name = @name AND QRcode = @qr
                ORDER BY Ward_no DESC;
            `);

        if (result.recordset.length > 0) {
            // Return the Ward_no from the query result
            return { Ward_no: result.recordset[0].Ward_no };
        } else {
            throw new Error("Ward number not found after updating QR code.");
        }
    } catch (error) {
        console.error("Error updating ward with new QR:", error);
        throw error;
    }
};

module.exports = { getAllWards, createWard, fetchAllWards, updateWardQR };
