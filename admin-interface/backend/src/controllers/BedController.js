const bedModel = require("../models/BedModel");

const handleGetAvailableBeds = async (req, res) => {
    try {
        const wardNo = req.params.wardNo;
        const beds = await bedModel.getAvailableBeds(wardNo);

        if (!beds.length) {
            return res.status(200).json({ availableBeds: [], message: "No available beds in this ward." });
        }

        const bedNumbers = beds.map(bed => bed.Bed_no); // Extract bed numbers

        res.status(200).json({
            status: "success",
            totalAvailableBeds: bedNumbers.length,
            availableBeds: bedNumbers,
        });

    } catch (error) {
        res.status(500).json({ error: "Internal Server Error" });
    }
};

module.exports = {
    handleGetAvailableBeds,
};
