const { sql, connectToDatabase } = require("../../config/db");
const crypto = require("crypto");

const getUserByResetToken = async (token) => {
    const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

    const pool = await connectToDatabase();

    const result = await pool.request()
        .input("token", sql.NVarChar(64), hashedToken)
        .query(`
            SELECT UserID, Reset_token_expiry
            FROM Login
            WHERE Reset_token = @token
        `);

    return result.recordset[0];
};

const updatePasswordByUserId = async (userId, hashedPassword) => {
    const pool = await connectToDatabase();

    await pool.request()
        .input("userId", sql.NVarChar(10), userId)
        .input("password", sql.NVarChar(255), hashedPassword)
        .query(`
            UPDATE Login
            SET Password = @password, Reset_token_expiry = GETDATE()
            WHERE UserID = @userId
        `);
};

module.exports = {updatePasswordByUserId, getUserByResetToken};
