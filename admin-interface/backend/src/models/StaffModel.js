const { sql, connectToDatabase } = require("../../config/db");
const crypto = require("crypto");

const getStaffIdByToken = async (token) => {
    try {
        console.log("Original Token:", token);
        const hashedToken = crypto.createHash("sha256").update(token).digest("hex"); // Hash the token
        console.log("Hashed Token (Before Saving):", hashedToken);

        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("hashedToken",sql.NVarChar(64), hashedToken) // Use hashed token
            .query(`
                SELECT l.UserID, u.Role
                FROM Login l
                INNER JOIN Users u ON l.UserID = u.UserID
                WHERE l.Reset_token = @hashedToken
                AND l.Reset_token_expiry IS NOT NULL
            `);

        return result.recordset.length > 0 ? result.recordset[0] : null;
    } catch (error) {
        console.error("Error retrieving user ID from token:", error);
        throw error;
    }
};


module.exports = { getStaffIdByToken};
