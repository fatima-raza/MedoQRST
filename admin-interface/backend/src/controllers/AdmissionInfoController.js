const express = require("express");
const admissionModel = require("../models/AdmissionInfoModel");
const patientInfoModel = require("../models/PatientInfoModel");

// Handle admission form submission (CREATE)
const handleCreateAdmission = async (req, res) => {
    // additional
    console.log("Received Admission Data:", req.body);

    try {
        const { patientId, dateOfAdmission, modeOfAdmission, wardNo, bedNo, admittedUnderCareOf } = req.body;

        // Ensure required fields are provided
        if (!patientId || !dateOfAdmission || !modeOfAdmission || !wardNo || !bedNo || !admittedUnderCareOf) {
            return res.status(400).json({ error: "All fields are required" });
        }

        // Validate mode of admission
        const validModes = ["from OPD", "Emergency", "Referred", "Transferred"];
        if (!validModes.includes(modeOfAdmission)) {
            return res.status(400).json({ error: "Invalid mode of admission" });
        }

        // Validate patient ID exists
        const patientExists = await patientInfoModel.getPatientById(patientId);
        if (!patientExists) {
            return res.status(404).json({ error: "Invalid patient ID. Patient does not exist." });
        }

        // Auto-generate the current time for Admission_time
        const now = new Date();
        const timeOfAdmission = now.toTimeString().split(' ')[0];

        // Insert admission data and get the generated admission number
        const admissionNo = await admissionModel.createAdmissionInfo(
            patientId, dateOfAdmission, timeOfAdmission, modeOfAdmission, wardNo, bedNo, admittedUnderCareOf
        );

        res.status(201).json({
            message: "Patient admitted successfully",
            admissionNo: admissionNo
        });

    } catch (error) {
        console.error("Error in handleCreateAdmission", error);
        res.status(400).json({ error: error.message });
    }
};

const handleGetAdmissionById = async (req, res) => {
    try {
        const { admissionNo } = req.params; // Get Admission_no from URL params

        if (!admissionNo) {
            return res.status(400).json({ error: "Admission number is required" });
        }

        const admissionData = await admissionModel.getAdmissionById(admissionNo);

        if (!admissionData) {
            return res.status(404).json({ error: "No record found for the given admission number" });
        }

        res.status(200).json(admissionData);

    } catch (error) {
        console.error("Error in handleGetAdmissionById:", error);
        res.status(400).json({ error: error.message });
    }
};

const handleGetAllAdmissions = async (req, res) => {
    try {
        const admissions = await admissionModel.getAllAdmissions();

        if (admissions.length === 0) {
            return res.status(404).json({ message: "No admissions found" });
        }

        res.status(200).json({ message: "Admissions retrieved successfully", data: admissions });

    } catch (error) {
        console.error("Error in handleGetAllAdmissions:", error);
        res.status(400).json({ error: error.message });
    }
};

// Handle full replacement admission update (PUT)
const handleUpdateAdmission = async (req, res) => {
    console.log("Received Update Data:", req.body);

    try {
        const { admissionNo } = req.params;
        const { patientId, dateOfAdmission, modeOfAdmission, wardNo, bedNo, admittedUnderCareOf } = req.body;

        // Ensure all fields are provided
        if (!admissionNo || !patientId || !dateOfAdmission || !modeOfAdmission || !wardNo || !bedNo || !admittedUnderCareOf) {
            return res.status(400).json({ error: "All fields are required for updating admission" });
        }

        // Validate mode of admission
        const validModes = ["from OPD", "Emergency", "Referred", "Transferred"];
        if (!validModes.includes(modeOfAdmission)) {
            return res.status(400).json({ error: "Invalid mode of admission" });
        }

        // Validate patient ID exists
        const patientExists = await patientInfoModel.getPatientById(patientId);
        if (!patientExists) {
            return res.status(404).json({ error: "Invalid patient ID. Patient does not exist." });
        }

        // Perform the update
        const isUpdated = await admissionModel.updateAdmissionInfo(
            admissionNo, patientId, dateOfAdmission, modeOfAdmission, wardNo, bedNo, admittedUnderCareOf
        );

        if (!isUpdated) {
            return res.status(404).json({ error: "Admission record not found or no changes made" });
        }

        res.status(200).json({
            message: "Admission updated successfully",
            admissionNo: admissionNo
        });

    } catch (error) {
        console.error("Error in handleUpdateAdmission:", error);
        res.status(400).json({ error: error.message });
    }
};

// Handle deleting an admission (DELETE)
const handleDeleteAdmission = async (req, res) => {
    console.log("Received Delete Request for Admission No:", req.params.admissionNo);

    try {
        const { admissionNo } = req.params;

        if (!admissionNo) {
            return res.status(400).json({ error: "Admission number is required" });
        }

        // Perform the deletion
        const isDeleted = await admissionModel.deleteAdmissionInfo(admissionNo);

        if (!isDeleted) {
            return res.status(404).json({ error: "Admission record not found" });
        }

        res.status(200).json({
            message: "Admission deleted successfully",
            admissionNo: admissionNo
        });

    } catch (error) {
        console.error("Error in handleDeleteAdmission:", error);
        res.status(400).json({ error: error.message });
    }
};

module.exports = { handleCreateAdmission, handleGetAdmissionById , handleGetAllAdmissions, handleUpdateAdmission, handleDeleteAdmission};

