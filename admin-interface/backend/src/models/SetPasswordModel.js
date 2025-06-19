const { sql, connectToDatabase } = require("../../config/db");
const bcrypt = require("bcrypt");
const crypto = require("crypto");

const setPassword = async (token, password) => {
    let transaction;
    
    try {
        const pool = await connectToDatabase();
        transaction = pool.transaction();
        await transaction.begin();

        console.log(token);
        const hashedToken = crypto.createHash("sha256").update(token).digest("hex");
        console.log(hashedToken);

        // Check if token is valid and not expired
        const result = await transaction.request()
            .input("hashedToken", sql.NVarChar(64), hashedToken)
            .query("SELECT UserID, Reset_token_expiry FROM Login WHERE Reset_token = @hashedToken");

        if (result.recordset.length === 0) {
            await transaction.rollback();
            return { success: false, error: "Invalid or expired token." };
        }

        const { UserID, Reset_token_expiry} = result.recordset[0];

        if (!Reset_token_expiry || new Date(Reset_token_expiry) < new Date()) {
            await transaction.rollback();
            return { success: false, error: "Reset token has expired." };
        }

        // **Generate salt & hash password**
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // set the password and clear reset token in one transaction
        await transaction.request()
            .input("userID", sql.NVarChar(10), UserID)
            .input("password", sql.NVarChar(255), hashedPassword)
            .query(`
                UPDATE Login
                SET Password = @password, Reset_token_expiry = GETDATE(), Password_set = 1
                WHERE UserID = @userID
            `);

        await transaction.commit();
        return {
            success: true,
            message: "Password set successfully."
        };
        
    } catch (error) {
        if (transaction) await transaction.rollback();
        console.error("Error setting password:", error);
        throw error;
    }
};

const verifyToken = async (token) => {
    const hashedToken = crypto.createHash("sha256").update(token).digest("hex");
    console.log("Hashed Token for verification:", hashedToken);  // Add this line for debugging

    const pool = await connectToDatabase();
    const result = await pool
        .request()
        .input("token", sql.NVarChar(64), hashedToken)
        .query("SELECT UserID, Reset_token_expiry FROM Login WHERE Reset_token = @token");

    if (result.recordset.length === 0) {
        return { valid: false, userId: null };
    }

    const resetTokenExpiry = result.recordset[0].Reset_token_expiry;
    
    // Check if the token has expired
    if (resetTokenExpiry < new Date()) {
        return { valid: false, message: "Token has expired", userId: result.recordset[0].UserID };
    }

    // token is valid
    return { valid: true, userId: result.recordset[0].UserID };
};

const isPasswordSet = async (userId) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("userID", sql.NVarChar(10), userId)
            .query(`
            SELECT
                CASE
                    WHEN Password_set = 1 THEN 1
                    ELSE 0
                END AS hasPassword
            FROM Login
            WHERE UserID = @userID
            `);
        
        console.log("Password check result:", result.recordset);
        return result.recordset[0]?.hasPassword === 1;
    } catch (error) {
        console.error("Error in isPasswordSet:", error);
        throw error;
    }
};

module.exports = {isPasswordSet, setPassword, verifyToken }