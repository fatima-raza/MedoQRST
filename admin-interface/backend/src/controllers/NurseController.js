const nurseModel = require("../models/NurseModel");

const handleCreateNurse = async (req, res) => {
    try {
        const { name, phone, age, gender, cnic, address, email } = req.body;

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

        // checking for existing nurses
        const existingNurse = await nurseModel.getNurseByCNIC(cnic);
        if (existingNurse) {
            return res.status(409).json({ error: "A nurse with this CNIC no. already exists." });
        }
        
        // Insert user into Users table
        const result = await nurseModel.createNurse(name, phone, age, gender, cnic, address, email);
        
        if (result.error) {
            return res.status(500).json({ error: "Nurse creation failed", details: result.error });
        }

        res.status(201).json({
            message: "Nurse registered successfully. Check email to change the auto-generated password.",
            userId: result.userId,
            username: result.username,
        });

    } catch (error) {
        console.error("Error creating nurse:", error);
        res.status(500).json({ error: "Registration failed", details: error.message });
    }
};

const handleGetAllNurses = async (req, res) => {
    try {
        const nurses = await nurseModel.getAllNurses();
        res.status(200).json(nurses);
    } catch (error) {
        console.error("Error in getAllNurses:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

// Get nurse details by ID (GET by id)
const handleGetNurseById = async (req, res) => {
    try {
        const { id } = req.params; // Extract ID from request URL

        // Call model function to fetch nurse data
        const nurse = await nurseModel.getNurseById(id);

        if (!nurse) {
            return res.status(404).json({ error: "Nurse not found" });
        }

        res.status(200).json(nurse);
    } catch (error) {
        console.error("Error in getNurse:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

module.exports = {
    handleGetAllNurses, handleCreateNurse, handleGetNurseById
};

