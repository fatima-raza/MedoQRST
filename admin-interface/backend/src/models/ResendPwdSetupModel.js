const { sql, connectToDatabase } = require("../../config/db");

const updateResetToken = async (userId, hashedResetToken, resetTokenExpiry) => {
    try {
        const pool = await connectToDatabase();
        await pool.request()
            .input("userId", sql.NVarChar(10), userId)
            .input("resetToken", sql.NVarChar(64), hashedResetToken)
            .input("resetTokenExpiry", sql.DateTime, resetTokenExpiry)
            .query("UPDATE Login SET Reset_token = @resetToken, Reset_token_expiry = @resetTokenExpiry WHERE UserID = @userId");
    } catch (error) {
        console.error("Error in updateResetToken:", error);
        throw error;
    }
};

const getResetToken = async (userId) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("userID", sql.NVarChar(10), userId)
            .query("SELECT Reset_token, Reset_token_expiry, UserID FROM Login WHERE UserID = @userID");

        return result.recordset.length > 0 ? result.recordset[0] : null;
    } catch (error) {
        console.error("Error in getResetToken:", error);
        throw error;
    }
};

module.exports = {updateResetToken, getResetToken }