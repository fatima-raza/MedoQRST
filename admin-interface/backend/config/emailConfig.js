const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

/**
 * Sends an email
 * @param {string} to - Receiver email
 * @param {string} subject - Email subject
 * @param {string} text - Email body content
 * @returns {Promise<{success: boolean, error?: string}>}
 */

const sendEmail = async (to, subject, htmlContent) => {
    try {
        let info = await transporter.sendMail({
            from: `"MEDOQRST - Hospital Wards Management System" <medoqrst@gmail.com>`,
            to,
            subject,
            html: htmlContent,
        });

        console.log("Email sent: " + info.response);
        return { success: true };
    } catch (error) {
        console.error("Email sending error:", error);
        return { success: false, error: error.message };
    }
};

module.exports = { sendEmail };
