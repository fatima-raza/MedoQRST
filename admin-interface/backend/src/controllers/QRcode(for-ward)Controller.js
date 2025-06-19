const qrcodeModel = require('../models/QRcode(for-ward)Model');

const handleGetAllQRcodes = async (req, res) => {
    try {
        const wards = await qrcodeModel.getAllQRcodes();
        res.status(200).json({
            wards,
        });
    } catch (error) {
        res.status(500).json({ error: "Internal Server Error" });
    }
};

const handleCreateQRcode = async (req, res) => {
    try {
        const newQR = await qrcodeModel.createQRcode(assignedTo);

        res.status(201).json({
            message: "QR code created successfully",
            qrcode: newQR,
        });
    } catch (error) {
        console.error("Error creating QR code:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

module.exports = { handleGetAllQRcodes, handleCreateQRcode };
