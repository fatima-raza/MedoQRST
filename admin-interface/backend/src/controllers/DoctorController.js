const doctorModel = require("../models/DoctorModel");

const handleCreateDoctor = async (req, res) => {
    try {
        const { name, phone, age, gender, cnic, address, specialization, department, email } = req.body;

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

        // checking for existing doctors
        const existingDoctor = await doctorModel.getDoctorByCNIC(cnic);
        if (existingDoctor) {
            return res.status(409).json({ error: "A doctor with this CNIC no. already exists." });
        }
        
        // Insert user into Users table
        const result = await doctorModel.createDoctor(name, phone, age, gender, cnic, address, specialization, department, email);
        
        if (result.error) {
            return res.status(500).json({ error: "Doctor creation failed", details: result.error });
        }

        res.status(201).json({
            message: "Doctor registered successfully. Check email to change the auto-generated password.",
            userId: result.userId,
            username: result.username,
        });

    } catch (error) {
        console.error("Error creating doctor:", error);
        res.status(500).json({ error: "Registration failed", details: error.message });
    }
};

const handleGetAllDoctors = async (req, res) => {
    try {
        const searchQuery = req.query.search || '';
        console.log("Search query:", searchQuery);
        const doctors = await doctorModel.getAllDoctors(searchQuery);
        res.status(200).json(doctors);
    } catch (error) {
        console.error("Error in getAllDoctors:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

// Get doctor details by ID (GET by id)
const handleGetDoctorById = async (req, res) => {
    try {
        const { id } = req.params; // Extract ID from request URL

        // Call model function to fetch doctor data
        const doctor = await doctorModel.getDoctorById(id);

        if (!doctor) {
            return res.status(404).json({ error: "Doctor not found" });
        }

        res.status(200).json(doctor);
    } catch (error) {
        console.error("Error in getDoctor:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

module.exports = {
    handleGetAllDoctors, handleCreateDoctor, handleGetDoctorById
};

