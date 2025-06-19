const { sql } = require('../../config/db');

exports.fetchVitals = async (pool, admissionID) => {
    try {
        const result = await pool.request()
            .input("Admission_no", sql.NVarChar(10), admissionID)
            .query(`
       SELECT * from Vitals
WHERE
    Admission_no = @Admission_no
ORDER BY
    Recorded_at DESC;
    `);
        return result;
    } catch (error) {
        console.error("Error in fetchVitals:", error.message);
        throw error;
    }
};
