const { sql, connectToDatabase } = require("../../config/db");
const emailConfig = require("../../config/emailConfig");
const crypto = require("crypto");
const bcrypt = require("bcryptjs");

const createNurse = async (name, phone, age, gender, cnic, address, email) => {
    const pool = await connectToDatabase();
    let userId;
    const transaction = await pool.transaction();

    try{
        await transaction.begin(); // Begin transaction
        await transaction.request()
        .input("name", sql.NVarChar(100), name)
        .input("phone", sql.NVarChar(12), phone)
        .input("age", sql.Int, age)
        .input("gender", sql.Char(1), gender)
        .input("cnic", sql.Char(13), cnic)
        .input("address", sql.NVarChar(255), address)
        .input("role", sql.NVarChar(10), "Nurse")
        .query(`INSERT INTO Users (Name, Contact_number, Age, Gender, CNIC, Address, Role)
            VALUES (@name, @phone, @age, @gender, @cnic, @address, @role)`);
    
        // Fetch generated UserID using CNIC
        const userResult = await transaction.request()
            .input("cnic", sql.Char(13), cnic)
            .query(`
                SELECT UserID FROM Users WHERE CNIC = @cnic
            `);

        if (!userResult.recordset || userResult.recordset.length === 0) {
            throw new Error("Failed ot retrieve the generated UserId after insertion.");
        }

        userId = userResult.recordset[0].UserID;

        await transaction.request()
            .input("nurseId", sql.NVarChar(10), userId)
            .input("email", sql.NVarChar(255), email)
            .query(`UPDATE Nurse
                SET Email = @email
                WHERE NurseID = @nurseId
                `);

        /// Generate username in the format name-dXXXXX for Nurse
        const username = name.replace(/\s+/g, "").toLowerCase() + "-n" + userId.replace("N-", "");

        const tempPassword = crypto.randomBytes(6).toString("base64"); // around 8 chars
        const hashedPassword = await bcrypt.hash(tempPassword, 10);

        // Generate reset token for password setup
        const resetToken = crypto.randomBytes(32).toString("hex");
        console.log(resetToken);
        const hashedResetToken = crypto.createHash("sha256").update(resetToken).digest("hex");
        const resetTokenExpiry = new Date(Date.now() + 30 * 60 * 1000).toISOString(); // Expires in 30 minutes
        console.log(hashedResetToken);

        // Insert login credentials
        await transaction.request()
            .input("userID", sql.NVarChar(10), userId)
            .input("username", sql.NVarChar(50), username)
            .input("password", sql.NVarChar(255), hashedPassword)
            .input("resetToken", sql.NVarChar(64), hashedResetToken)
            .input("resetTokenExpiry", sql.DateTime, resetTokenExpiry)
            .query("INSERT INTO Login (UserID, User_name, Password, Reset_token, Reset_token_expiry) VALUES (@userID, @username, @password, @resetToken, @resetTokenExpiry)");
                    
        // Send password reset email
        const resetLink = `${process.env.CLIENT_BASE_URL}/set-password?token=${resetToken}`;
        const emailHtml = `
            <p>Hello <b>${name}</b>,</p>
            <p>Your admin account has been created successfully.</p>
            <p><b>Username:</b> ${username}</p>
            <p><b>Temporary Password:</b> ${tempPassword}</p><br>
            <p>Please change your password using the link below (valid for 30 minutes):</p>
            <p><a href="${resetLink}" target="_blank">Change Your Password</a></p>
            <br>
            <p><i>Note: For your security, please do not share this password and update it immediately.</i></p>
            <br>
            <p>Thanks,</p>
            <p><b>MedoQRST - Hospital Wards Management System</b></p>
        `;

        const emailResponse = await emailConfig.sendEmail(email, "Set Up Your Password", emailHtml);
        if (!emailResponse.success) {
            console.error("Email sending failed:", emailResponse.error);
        }

        await transaction.commit();

        return { message: "Nurse created successfully", userId, username};

    } catch (error) {
        await transaction.rollback(); // Rollback changes on error
        console.error("Error creating nurse:", error);
        return { error: error.message };
    }
};

const getAllNurses = async (searchQuery) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("search", sql.VarChar, `%${searchQuery}%`)
            .query(`
                SELECT n.NurseID, u.Name
                FROM Nurse n
                INNER JOIN Users u ON n.NurseID = u.UserID
                WHERE u.Name LIKE @search
            `);

        return result.recordset;
    } catch (error) {
        console.error("Error fetching nurses:", error);
        throw error;
    }
};

const getNurseById = async (nurseId) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool
            .request()
            .input("nurseId", sql.NVarChar(10), nurseId.trim())
            .query(`
                SELECT n.Email, u.UserID, u.Name, u.Age, u.Gender, u.Contact_number, u.CNIC, u.Address
                FROM Nurse n
                INNER JOIN Users u ON n.NurseID = u.UserID
                WHERE UserID = @nurseId AND Role = 'Nurse'
            `);

            return result.recordset[0] || null;
    } catch (error) {
        console.error("Error in getNurseById:", error);
        throw error;
    }
};

const getNurseByCNIC = async (cnic) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("cnic", sql.Char(13), cnic)
            .query(`
                SELECT UserID, Name, Age, Gender, Contact_number, CNIC, Address
                FROM Users
                WHERE CNIC = @cnic AND Role = 'Nurse'
            `);

        console.log('query result: ', result.recordset);
        
        return result.recordset[0] || null;
    } catch (error) {
        console.error("Error in getNurseByCNIC:", error);
        throw error;
    }
};

const getNurseByEmail = async (email) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("email", sql.NVarChar(255), email)
            .query(
                `SELECT n.NurseID, u.Name
                FROM Nurse n
                INNER JOIN Users u ON n.NurseID = u.UserID
                WHERE n.Email = @email`
            );

        return result.recordset[0] || null;
    } catch (error) {
        console.error("Error in getNurseByEmail:", error);
        throw error;
    }
};

module.exports = {
    getAllNurses, createNurse, getNurseByCNIC, getNurseByEmail, getNurseById
};
