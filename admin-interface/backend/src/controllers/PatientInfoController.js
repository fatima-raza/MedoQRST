const express = require("express");
const patientInfoModel = require("../models/PatientInfoModel");

// Add a new patient (CREATE)
const handleCreatePatient = async (req, res) => {
    // additional
    console.log("Received Data:", req.body);

    try {
        const { Name, Age, Gender, Contact_number, CNIC, Address } = req.body;

        // Input validation
        // checking if required fields are provided
        if (!Name || !Age || !Gender || !CNIC) {
            return res.status(400).json({ error: "Name, Age Gender and CNIC no. are mandatory to enter" });
        }

        // checking only upper/lower case letters and spaces exist in name
        if (!/^[a-zA-Z\s'-]+$/.test(Name)) {
            return res.status(400).json({ error: "Invalid name. Only letters allowed." });
        }

        // age can not be negative
        if (!Number.isInteger(Age) || Age < 0) {
            return res.status(400).json({ error: "Invalid age. Age must be a positive number or 0." });
        }

        // 12 digit contact number allowed only
        if (Contact_number && !/^\d{12}$/.test(Contact_number)) {
            return res.status(400).json({ error: "Invalid phone number. Must be 12 digits." });
        }
        
        // 13-digit CNIC validation
        if (!/^\d{13}$/.test(CNIC)) {
            return res.status(400).json({ error: "Invalid CNIC number. Must be exactly 13 digits." });
        }

        const existingPatient = await patientInfoModel.getPatientByCNIC(CNIC);
        if (existingPatient) {
            return res.status(409).json({ error: "A patient with this CNIC already exists." });
        }

        // Call model function to insert patient and get the patient id for the next forms
        const newPatientId = await patientInfoModel.createPatient(Name, Age, Gender, Contact_number, CNIC, Address);

        if (!newPatientId) {
            return res.status(500).json({ error: "Failed to create patient." });
        }

        // Send response to frontend with PatientID
        res.status(201).json({ message: "Patient registered successfully", patientId: newPatientId });
    }
    catch (error) {
        console.error("Error in createPatient:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

// Get patient details by ID (GET by id)
const handleGetPatientById = async (req, res) => {
    try {
        const { id } = req.params; // Extract ID from request URL

        // Call model function to fetch patient data
        const patient = await patientInfoModel.getPatientById(id);

        if (!patient) {
            return res.status(404).json({ error: "Patient not found" });
        }

        res.status(200).json(patient);
    } catch (error) {
        console.error("Error in getPatient:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

// Get all patients (GET)
const handleGetAllPatients = async (req, res) => {
    try {
        const patients = await patientInfoModel.getAllPatients();
        res.status(200).json(patients);
    } catch (error) {
        console.error("Error in getAllPatients:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

// Update patient details (PUT)
const handleUpdatePatient = async (req, res) => {
    try {
        const { id } = req.params; // Extract patient ID from request URL
        if (!id) {
            return res.status(400).json({ error: "Patient ID is required." });
        }

        const { Name, Age, Gender, Contact_number, CNIC, Address } = req.body; //object destructuring

        // Input validation
        // Check if at least one field is provided to update
        if (!Name && Age === undefined && !Gender && !Contact_number && !CNIC && !Address) {
            return res.status(400).json({ error: "At least one field must be provided for update." });
        }

        // checking only upper/lower case letters and spaces exist in name
        if (Name && !/^[a-zA-Z\s]+$/.test(Name)) {
            return res.status(400).json({ error: "Invalid name. Only letters allowed." });
        }

        // age can not be negative
        if (Age !== undefined && (!Number.isInteger(Age) || Age < 0)) {
            return res.status(400).json({ error: "Invalid age. Age must be a positive number or 0." });
        }

        // 12 digit contact number allowed only
        if (Contact_number && !/^\d{12}$/.test(Contact_number)) {
            return res.status(400).json({ error: "Invalid phone number. Must be 12 digits." });
        }
        
        // 13-digit CNIC validation
        if (CNIC && !/^\d{13}$/.test(CNIC)) {
            return res.status(400).json({ error: "Invalid CNIC number. Must be exactly 13 digits." });
        }

        // check if patient exists
        const existingPatient = await patientInfoModel.getPatientById(id);
        if (!existingPatient) {
            return res.status(404).json({ error: "Patient not found." });
        }

        if (CNIC && CNIC !== existingPatient.CNIC) {
            const isCNICExists = await patientInfoModel.getPatientByCNIC(CNIC);
            if (isCNICExists) {
                return res.status(400).json({ error: "CNIC already exists for another patient." });
            }
        }

        const updatedFields = { Name, Age, Gender, Contact_number, CNIC, Address };

        // Filter out undefined fields
        const filteredFields = Object.fromEntries(
            Object.entries(updatedFields).filter(([_, v]) => v !== undefined && v !== null)
        );

        // Skip update if no valid fields provided
        if (Object.keys(filteredFields).length === 0) {
            return res.status(400).json({ error: "No valid fields provided for update." });
        }

        const result = await patientInfoModel.updatePatient(id, filteredFields);

        if (!result || result.rowsAffected[0] === 0) {
            return res.status(400).json({ error: "No changes were made to the patient record." });
        }

        res.status(200).json({ message: "Patient updated successfully" });

    } catch (error) {
        console.error("Error in updatePatient:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

// Delete patient (DELETE)
const handleDeletePatient = async (req, res) => {
    try {
        const { id } = req.params; // Extract patient ID from request URL

        if (!id) {
            return res.status(400).json({ error: "Patient ID is required." });
        }

        // Check if the patient exists first
        const existingPatient = await patientInfoModel.getPatientById(id);
        if (!existingPatient) {
            return res.status(404).json({ error: "Patient not found." });
        }

        // Attempt to delete the patient
        await patientInfoModel.deletePatient(id);

        res.status(200).json({ message: "Patient deleted successfully" });

    } catch (error) {
        console.error("Error in deletePatient:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

const handleSearchPatient = async (req, res) => {
    try {
        const { identifier } = req.params;

        console.log("Received identifier: ", identifier);

        let patient = null;

        // Check if the identifier is a CNIC (13 digits) or an ID (starts with 'P-')
        if (/^P-\d{5}$/.test(identifier)) {
            console.log("Searching by ID:", identifier);
            patient = await patientInfoModel.getPatientById(identifier);
        } else if (/^\d{13}$/.test(identifier)) {
            console.log("Searching by CNIC:", identifier);
            patient = await patientInfoModel.getPatientByCNIC(identifier);
        } else {
            return res.status(400).json({ 
                found: false,
                message: "Invalid identifier format. Provide a valid Patient ID or CNIC." 
            });
        }
        
        if (!patient) {
            return res.status(404).json({
                found: false,
                message: "No previous record found."
            });
        }

        res.status(200).json({
            found: true,
            data: patient
        });
        
    } catch (error) {
        console.error("Error searching patient:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

module.exports = { handleCreatePatient, handleGetPatientById, handleGetAllPatients, handleUpdatePatient, handleDeletePatient, handleSearchPatient };

