const emergencyContactModel = require("../models/EmergencyContactModel");
const admissionInfoModel = require("../models/AdmissionInfoModel");

const handleEmergencyContact = async (req, res) => {
    try {
        const { admissionNo, name, relationship, contactNo, address } = req.body;

        // Basic validation
        if (!admissionNo || !name || !relationship || !contactNo) {
            return res.status(400).json({ error: "Missing required fields" });
        }

        // Validate patient ID exists
        const admissionExists = await admissionInfoModel.getAdmissionById(admissionNo);
        if (!admissionExists) {
            return res.status(404).json({ error: "Invalid admission no. This admission does not exist." });
        }

        // checking only upper/lower case letters and spaces exist in name
        if (!/^[a-zA-Z\s'-]+$/.test(name)) {
            return res.status(400).json({ error: "Invalid name. Only letters allowed." });
        }

        // 12 digit contact number allowed only
        if (contactNo && !/^\d{12}$/.test(contactNo)) {
            return res.status(400).json({ error: "Invalid phone number. Must be 12 digits." });
        }

        const admissionNumber = await emergencyContactModel.createEmergencyContact(admissionNo, name, relationship, contactNo, address);

        res.status(201).json({
            message: "Emergency Contact details enterred successfully",
            admissionNo: admissionNumber
        });

    } catch (error) {
        console.error("Error in handleEmergencyContact", error);
        res.status(400).json({ error: error.message });
    }
};

// Get Emergency Contact by Admission No
const handleGetEmergencyContactById = async (req, res) => {
    try {
        const { admissionNo } = req.params;

        if (!admissionNo) {
            return res.status(400).json({ error: "Admission number is required" });
        }

        const emergencyContact = await emergencyContactModel.getEmergencyContactByAdmissionNo(admissionNo);

        if (!emergencyContact) {
            return res.status(404).json({ error: "No emergency contact found for this admission number." });
        }

        res.status(200).json(emergencyContact);
    } catch (error) {
        console.error("Error in getEmergencyContactById", error);
        res.status(400).json({ error: error.message });
    }
};

// Get All Emergency Contacts
const handleGetAllEmergencyContacts = async (req, res) => {
    try {
        const emergencyContacts = await emergencyContactModel.getAllEmergencyContacts();
    if (emergencyContacts.length === 0) {
        return res.status(404).json({ message: "No emergency contacts found" });
    }
    res.status(200).json({ message: "Emergency details retrieved successfully", data: emergencyContacts });

    } catch (error) {
        console.error("Error in getAllEmergencyContacts", error);
        res.status(500).json({ error: error.message });
    }
};

module.exports = {
    handleEmergencyContact,
    handleGetEmergencyContactById,
    handleGetAllEmergencyContacts
};
