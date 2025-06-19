const { sql } = require("../../config/db");

exports.fetchNextOfKinByAdmissionID = async (pool, admissionID) => {
    const result = await pool
        .request()
        .input("Admission_no", sql.NVarChar(10), admissionID)
        .query(`
            SELECT
                Admission_no,
                Name,
                Address,
                Contact_no,
                Relationship
            FROM NextOfKin
            WHERE Admission_no = @Admission_no
        `);

    return result.recordset;
};
