const { sql, connectToDatabase } = require("../../config/db");
const bcrypt = require("bcrypt");
const adminModel = require("./AdminModel");

const getUserByUsername = async (username) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("username", sql.NVarChar, username)
            .query(`
                SELECT UserID, Username, Password, Role
                FROM Users
                WHERE Username = @username
            `);

        return result.recordset.length > 0 ? result.recordset[0] : null;
    } catch (error) {
        console.error("Error fetching user:", error);
        throw error;
    }
};

module.exports = { getUserByUsername };
