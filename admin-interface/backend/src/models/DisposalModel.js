const { sql } = require('../../config/db');

exports.updateDisposalStatus = async (pool, admissionID, status) => {
    try {
        const result = await pool.request()
            .input("Disposal_status", sql.NVarChar(50), status)
            .input("Admission_no", sql.NVarChar(10), admissionID)
            .query(`
                UPDATE PatientDetails
                SET Disposal_status = @Disposal_status
                WHERE Admission_no = @Admission_no
            `);

        return result;
    } catch (error) {
        console.error("Error in updateDisposalStatus:", error.message);
        throw error;
    }
};
