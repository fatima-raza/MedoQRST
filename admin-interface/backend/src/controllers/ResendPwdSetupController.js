const setPasswordModel = require("../models/SetPasswordModel");
const doctorModel = require("../models/DoctorModel");
const nurseModel = require("../models/NurseModel");
const staffModel = require("../models/StaffModel");
const resendPwdSetupModel = require("../models/ResendPwdSetupModel");
const emailConfig = require("../../config/emailConfig");
const crypto = require("crypto");

const handleResendPwdSetupLink = async (req, res) => {
    const { oldToken } = req.query;

    if (!oldToken) {
        return res.status(400).json({ status: "error", error: "Previous token is required" });
    }

    try {
        // Retrieve the UserID from the previous token
        const userData = await staffModel.getStaffIdByToken(oldToken);
        if (!userData) {
            return res.status(404).json({ status: "error", error: "Unable to retrieve user id from token" });
        }
        
        const { UserID, Role } = userData;
        console.log(UserID);
        console.log(Role);

        // Check if the User exists
        let existingUser;
        if (Role === "Doctor") {
            existingUser = await doctorModel.getDoctorById(UserID);
        } else if (Role === "Nurse") {
            existingUser = await nurseModel.getNurseById(UserID);
        } else {
            return res.status(400).json({ status: "error", error: "Invalid role detected" });
        }

        if (!existingUser) {
            return res.status(404).json({ status: "error", error: "No staff account found." });
        }

        // Check if password is already set
        const hasPassword = await setPasswordModel.isPasswordSet(UserID);
        if (hasPassword) {
            return res.status(400).json({ status: "already_set", error: "Password is already set. No need to reset." });
        }

        // Fetch email from Users table using userId
        if (!existingUser.Email) {
            return res.status(500).json({ status: "error", error: "Email not found. Please contact admin." });
        }

        const storedEmail = existingUser.Email; // Use this email to resend the link

        // Check if an existing reset token is still valid
        const existingTokenData = await resendPwdSetupModel.getResetToken(UserID);
        const now = new Date();

        if (existingTokenData) {
            // If existing token is still valid
            if (new Date(existingTokenData.Reset_token_expiry) > now) {
                return res.status(400).json({
                    status: "error",
                    error: "Existing password setup link is still valid. Please check your email."
                });
            }
            
            // Cooldown check (5 minutes)
            const lastRequestTime = new Date(existingTokenData.Reset_token_expiry - 30 * 60 * 1000);
            const cooldownPeriod = 5 * 60 * 1000; // 5 minutes
            
            if (now - lastRequestTime < cooldownPeriod) {
                return res.status(400).json({
                    status: "error",
                    error: "Please wait 5 minutes before requesting another link."
                });
            }
        }

        // Generate new reset token
        const resetToken = crypto.randomBytes(32).toString("hex");
        console.log(resetToken);
        const hashedResetToken = crypto.createHash("sha256").update(resetToken).digest("hex");
        console.log(hashedResetToken);
        const resetTokenExpiry = new Date(Date.now() + 30 * 60 * 1000).toISOString(); // Expires in 30 minutes

        // Save reset token in database
        await resendPwdSetupModel.updateResetToken(UserID, hashedResetToken, resetTokenExpiry);

        // Send email with reset link
        const resetLink = `${process.env.CLIENT_BASE_URL}/set-password?token=${resetToken}`;
        const emailHtml = `
            <p>Hello <b>${existingUser.Name}</b>,</p>
            <p>Your account has been created successfully.</p>
            <p><b>Temporary Password:</b> ${result.tempPassword}</p><br><br>
            <p>Please change your password using the link below (valid for 30 minutes):</p>
            <p><a href="${resetLink}" target="_blank">Change Your Password</a></p>
            <br>
            <p><i>Note: For your security, please do not share this password and update it immediately.</i></p>
            <br>
            <p>Thanks,</p>
            <p><b>MedoQRST - Hospital Wards Management System</b></p>

        `;

        const emailResponse = await emailConfig.sendEmail(storedEmail, "Set Up Your Password - New Link Provided", emailHtml);

        if (!emailResponse.success) {
            console.error("Email sending failed:", emailResponse.error);
        }

        res.status(200).json({
            status: "success",
            message: "Resent Password setup link successfully!. Check your email",
            newToken: resetToken, // Send new token
        });
    } catch (error) {
        console.error("Error resending password setup link:", { message: error.message, stack: error.stack });
        res.status(500).json({ status: "error", error: "Internal Server Error", details: error.message });
    }
};

module.exports = { handleResendPwdSetupLink };
