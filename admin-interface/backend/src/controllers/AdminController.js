const adminModel = require("../models/AdminModel");

const handleCreateAdmin = async (req, res) => {
    try {
        const { name, phone, age, gender, cnic, address, email} = req.body;

        // checking required fields are provided
        if (!name || !gender || !cnic  || !age || !email || !phone || !address) {
            return res.status(400).json({ error: "All required fields must be provided" });
            }

        // checking only upper/lower case letters and spaces exist in name
        if (!/^[a-zA-Z\s'-]+$/.test(name)) {
            return res.status(400).json({ error: "Invalid name. Only letters allowed." });
        }

        // age can not be negative
        if (!Number.isInteger(age) || age < 0) {
            return res.status(400).json({ error: "Invalid age. Age must be a positive number or 0." });
        }

        // 12 digit contact number allowed only
        if (phone && !/^\d{12}$/.test(phone)) {
            return res.status(400).json({ error: "Invalid phone number. Must be 12 digits." });
        }
        
        // 13-digit CNIC validation
        if (!/^\d{13}$/.test(cnic)) {
            return res.status(400).json({ error: "Invalid CNIC number. Must be exactly 13 digits." });
        }

        // email address validation (for gmail only)
        if (!/^[a-zA-Z0-9._%+-]+@gmail\.com$/.test(email)) {
            return res.status(400).json({ error: "Invalid email. Only Gmail addresses (e.g., example@gmail.com) are allowed." });
        }

        // checking for existing admins
        const existingAdmin = await adminModel.getAdminByCNIC(cnic);
        if (existingAdmin) {
            return res.status(409).json({ error: "An admin with this CNIC no. already exists." });
        }
        
        // Insert user into Users table
        const result = await adminModel.createAdmin(name, phone, age, gender, cnic, address, email);
        
        if (result.error) {
            return res.status(500).json({ error: "Admin creation failed", details: result.error });
        }
        
        res.status(201).json({
            message: "Admin registered successfully. Check email to change the auto-generated password.",
            userId: result.userId,
            username: result.username,
        });

    } catch (error) {
        console.error("Error creating admin:", error);
        res.status(500).json({ error: "Registration failed", details: error.message });
    }
};

const handleChangeAdminPassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        console.log("Session data:", req.session);
        const userId = req.session.userId;

        if (!userId) {
            return res.status(401).json({ error: "Unauthorized. Please log in again." });
        }

        if (!oldPassword || !newPassword) {
            return res.status(400).json({ error: "Old and new passwords are required." });
        }

        const result = await adminModel.changeAdminPassword(userId, oldPassword, newPassword);

        if (result.error) {
            return res.status(400).json({ error: result.error });
        }

        return res.status(200).json({ message: "Password changed successfully." });

    } catch (error) {
        console.error("Error changing password:", error);
        return res.status(500).json({ error: "Internal server error", details: error.message });
    }
};

const handleGetAllAdmins = async (req, res) => {
    try {
        const admins = await adminModel.getAllAdmins();
        res.status(200).json(admins);
    } catch (error) {
        console.error("Error in getAllAdmins:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

const handleGetAdminById = async (req, res) => {
    try {
        const { id } = req.params; // Extract ID from request URL

        // Call model function to fetch admin data
        const admin = await adminModel.getAdminById(id);

        if (!admin) {
            return res.status(404).json({ error: "Admin not found" });
        }

        res.status(200).json(admin);
    } catch (error) {
        console.error("Error in getAdmin:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

const handleForgotAdminPasswordReset = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                error: "Email is required.",
            });
        }
            
        const trimmedEmail = email.trim();
        const isValidGmail = /^[a-zA-Z0-9._%+-]+@gmail\.com$/.test(trimmedEmail);

        if (!isValidGmail) {
            return res.status(400).json({
                success: false,
                error: "Invalid email format"
            });
        }
        
        const result = await adminModel.forgotAdminPasswordReset(trimmedEmail);

        if (result.success) {
            return res.status(200).json(result);
        } else {
            return res.status(400).json(result);
        }
    } catch (error) {
        console.error("[Controller] Error:", error);
        return res.status(500).json({ error: "Server error." });
    }
};

module.exports = {
    handleGetAllAdmins, handleCreateAdmin, handleGetAdminById, handleChangeAdminPassword, handleForgotAdminPasswordReset
};

