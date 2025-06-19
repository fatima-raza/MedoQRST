const wardModel = require('../models/WardModel');
const qrcodeModel = require("../models/QRcode(for-ward)Model");
const { beginTransaction, connectToDatabase } = require("../../config/db")

const getAllWards = async (req, res) => {
    try {
        const pool = await connectToDatabase();
        const result = await wardModel.fetchAllWards(pool);

        if (!result || result.length === 0) {
            console.warn("No ward records found.");
            return res.status(404).json({ message: "No ward records found." });
        }

        res.status(200).json({ data: result });
    } catch (error) {
        console.error("Error fetching ward details:", error.message);
        res.status(500).json({ error: error.message });
    }
};

const handleGetAllWards = async (req, res) => {
    try {
        const wards = await wardModel.getAllWards();
        res.status(200).json({
            wards,
        });
    } catch (error) {
        res.status(500).json({ error: "Internal Server Error" });
    }
};

const handleCreateWard = async (req, res) => {
    const { wardName } = req.body;
    const transaction = await beginTransaction();

    try {
        const qrResponse = await qrcodeModel.createQRcode(transaction);
        console.log("qrResponse:", qrResponse);

        if (!qrResponse || !qrResponse.qrID) {
            await transaction.rollback();
            return res.status(500).json({ message: "Failed to generate QR code" });
        }

        const qrID = qrResponse.qrID;

        const wardResult = await wardModel.createWard(wardName, qrID, transaction);

        if (!wardResult || !wardResult.Ward_no) {
            await transaction.rollback();
            return res.status(500).json({ message: "Failed to create ward" });
        }

        await transaction.commit();

        res.status(201).json({
            message: "Ward and QR code created successfully",
            ward: {
                wardNo: wardResult.Ward_no,
                wardName,
                qrID
            }
        });

    } catch (error) {
        await transaction.rollback()
        console.error("Error in handleCreateWard:", error);
        res.status(500).json({ message: "Error creating ward", error: error.message });
    }
};

const handleRegenerateWardQR = async (req, res) => {
    const { wardName } = req.body;
    const transaction = await beginTransaction();

    try {
        // Invalidate old QR for this ward
        const invalidationResult = await qrcodeModel.invalidateOldWardQR(wardName, transaction);
        if (!invalidationResult) {
            await transaction.rollback();
            return res.status(404).json({ message: "Ward not found or QR not updated" });
        }

        // Generate new QR code
        const qrResponse = await qrcodeModel.createQRcode(transaction);
        if (!qrResponse || !qrResponse.qrID) {
            await transaction.rollback();
            return res.status(500).json({ message: "Failed to generate new QR code" });
        }

        const newQRID = qrResponse.qrID;

        // Update ward with new QR code
        const updateResult = await wardModel.updateWardQR(wardName, newQRID, transaction);
        if (!updateResult) {
            await transaction.rollback();
            return res.status(500).json({ message: "Failed to update ward with new QR code" });
        }

        await transaction.commit();

        res.status(200).json({
            message: "QR code regenerated and assigned to ward successfully",
            ward: {
                wardNo: updateResult.Ward_no,
                wardName,
                newQRID
            }
        });
    } catch (error) {
        await transaction.rollback();
        console.error("Error in handleRegenerateWardQR:", error);
        res.status(500).json({ message: "Error regenerating QR code", error: error.message });
    }
};


module.exports = { handleGetAllWards, handleCreateWard, getAllWards, handleRegenerateWardQR};
