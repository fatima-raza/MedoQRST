const { sql, connectToDatabase } = require("../../config/db");
const emailConfig = require("../../config/emailConfig");
const bcrypt = require("bcrypt");
const crypto = require("crypto");

const createAdmin = async (name, phone, age, gender, cnic, address, email) => {
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
        .input("role", sql.NVarChar(10), "Admin")
        .query(`INSERT INTO Users (Name, Contact_number, Age, Gender, CNIC, Address, Role)
            VALUES (@name, @phone, @age, @gender, @cnic, @address, @role)`);
        
        // Fetch generated UserID using CNIC
        const userResult = await transaction.request()
            .input("cnic", sql.Char(13), cnic)
            .query(`
                SELECT UserID FROM Users WHERE CNIC = @cnic
            `);

        if (!userResult.recordset || userResult.recordset.length === 0) {
            throw new Error("Failed to retrieve the generated UserId after insertion.");
        }

        userId = userResult.recordset[0].UserID;

        await transaction.request()
            .input("adminId", sql.NVarChar(10), userId)
            .input("email", sql.NVarChar(255), email)
            .query(`UPDATE Admin
                SET Email = @email
                WHERE AdminID = @adminId
                `);
        
        // Generate username in the format admin-XXXXX for Admin
        const username = "admin-" + userId.replace("A-", "");

        // Generate temp password and reset token
        const tempPassword = crypto.randomBytes(6).toString("base64");
        const hashedPassword = await bcrypt.hash(tempPassword, 10);

        const resetToken = crypto.randomBytes(32).toString("hex");
        const hashedResetToken = crypto.createHash("sha256").update(resetToken).digest("hex");
        const resetTokenExpiry = new Date(Date.now() + 30 * 60 * 1000).toISOString();

        // Insert login credentials
        await transaction.request()
            .input("userID", sql.NVarChar(10), userId)
            .input("username", sql.NVarChar(50), username)
            .input("password", sql.NVarChar(255), hashedPassword)
            .input("resetToken", sql.NVarChar(64), hashedResetToken)
            .input("resetTokenExpiry", sql.DateTime, resetTokenExpiry)
            .query(`
                INSERT INTO Login (UserID, User_name, Password, Reset_token, Reset_token_expiry)
                VALUES (@userID, @username, @password, @resetToken, @resetTokenExpiry)
            `);
        
        // Send password reset email
        const resetLink = `${process.env.CLIENT_BASE_URL}/set-password?token=${resetToken}`;
        const emailHtml = `
            <p>Hello <b>${name}</b>, </p>
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

        return {message: "Admin created successfully", userId, username};

    } catch (error) {
        await transaction.rollback(); // Rollback changes on error
        console.error("Error creating admin:", error);
        return { error: error.message };
    }
};

const changeAdminPassword = async (userId, oldPassword, newPassword) => {
    try {
        const pool = await connectToDatabase();

        // Fetch user info by username
        const result = await pool.request()
            .input("userId", sql.NVarChar(50), userId)
            .query("SELECT UserID, Password FROM Login WHERE UserID = @userId");

        if (!result.recordset.length) {
            return { error: "Admin not found." };
        }

        const { UserID, Password: currentHashedPassword } = result.recordset[0];

        // Compare old password
        const isMatch = await bcrypt.compare(oldPassword, currentHashedPassword);
        if (!isMatch) {
            return { error: "Incorrect old password." };
        }

        // Hash new password
        const hashedNewPassword = await bcrypt.hash(newPassword, 10);

        // Update password using UserID
        await pool.request()
            .input("userId", sql.NVarChar(10), UserID)
            .input("newPassword", sql.NVarChar(255), hashedNewPassword)
            .query("UPDATE Login SET Password = @newPassword WHERE UserID = @userId");

        return { success: true };

    } catch (error) {
        console.error("Error in changeAdminPassword:", error);
        return { error: error.message };
    }
};

const getAdminById = async (adminId) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool
            .request()
            .input("adminId", sql.NVarChar(10), adminId)
            .query(`
                SELECT u.UserID, u.Name, u.Age, u.Gender, u.Contact_number, u.CNIC, u.Address, a.Email
                FROM Admin a
                INNER JOIN Users u ON a.AdminID = u.UserID
                WHERE UserID = @adminId AND Role = 'Admin'
            `);

            return result.recordset[0] || null;
    } catch (error) {
        console.error("Error in getAdminById:", error);
        throw error;
    }
};

const getAllAdmins = async () => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .query(`
                SELECT UserID, Name, Age, Gender, Contact_number, CNIC, Address
                FROM Users
                WHERE Role = 'Admin'
            `);
        return result.recordset;
    } catch (error) {
        console.error("Error fetching all admins:", error);
        throw error;
    }
};

const getAdminByCNIC = async (cnic) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("cnic", sql.Char(13), cnic)
            .query(`
                SELECT UserID, Name, Age, Gender, Contact_number, CNIC, Address
                FROM Users
                WHERE CNIC = @cnic AND Role = 'Admin'
            `);

        console.log('query result: ', result.recordset);
        
        return result.recordset[0] || null;
    } catch (error) {
        console.error("Error in getAdminByCNIC:", error);
        throw error;
    }
};

const getAdminByUsername = async (username) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool
            .request()
            .input("username", sql.NVarChar(50), username)
            .query("SELECT * FROM Login WHERE User_name = @username");
        
        return result.recordset[0] || null;
    } catch (error) {
        console.error("Error fetching admin by username:", error);
        throw error;
    }
};

const forgotAdminPasswordReset = async (email) => {
    try {
        const pool = await connectToDatabase();

        // Check if email exists in Login via Admin
        const queryString = `
            SELECT L.UserID, L.User_name, U.Name
            FROM Login L
            JOIN Admin A ON A.AdminID = L.UserID
            JOIN Users U ON U.UserID = L.UserID
            WHERE A.Email COLLATE SQL_Latin1_General_CP1_CI_AS = @email
        `;

        const userQuery = await pool.request()
            .input("email", sql.NVarChar(255), email)
            .query(queryString);

        if (userQuery.recordset.length === 0) {
            return {
                success: false,
                error: "No admin found with this email."
            };
        }

        const { UserID, User_name, Name } = userQuery.recordset[0];
        console.log("[Model] Found admin:", { UserID, User_name, Name });

        // Generate new token
        const resetToken = crypto.randomBytes(32).toString("hex");
        const hashedResetToken = crypto.createHash("sha256").update(resetToken).digest("hex");
        const resetTokenExpiry = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes

        // Step 3: Update Login table with new token
        await pool.request()
            .input("userID", sql.NVarChar(10), UserID)
            .input("resetToken", sql.NVarChar(64), hashedResetToken)
            .input("resetTokenExpiry", sql.DateTime, resetTokenExpiry)
            .query(`
                UPDATE Login
                SET Reset_token = @resetToken,
                    Reset_token_expiry = @resetTokenExpiry
                WHERE UserID = @userID
            `);

        console.log(resetToken);
        console.log(hashedResetToken)
        
        // Step 4: Send email
        const resetLink = `${process.env.CLIENT_BASE_URL}/reset-password?token=${resetToken}`;
        console.log(resetLink);
        const emailHtml = `
            <p>Hi ${Name} (${User_name}),</p>
            <p>You requested a password reset.</p>
            <p><a href="${resetLink}" target="_blank">Click here to reset your password</a></p>
            <p>This link will expire in 30 minutes.</p>
            <br>
            <p><i>If you did not request this, please ignore this email.</i></p>
            <br>
            <p>Thanks,</p>
            <p><b>MedoQRST - Hospital Wards Management System</b></p>
        `;

        const emailResponse = await emailConfig.sendEmail(email, "Reset Your Admin Account Password", emailHtml);
        
        if (!emailResponse.success) {
            return {
                success: false,
                error: "Failed to send email. Please try again later.",
            };
        }

        return {
            success: true,
            message: "Reset Password link sent to email. Please check your Email",
        };

    } catch (error) {
        console.error("Error in forgotPassword:", error);
        return { success: false, error: error.message };
    }
};

module.exports = {
    getAdminById, createAdmin, getAllAdmins, getAdminByCNIC, getAdminByUsername, changeAdminPassword, forgotAdminPasswordReset
};
