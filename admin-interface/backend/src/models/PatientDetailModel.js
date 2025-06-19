const { sql } = require('../../config/db');

exports.fetchPatientDetails = async (pool, admissionID) => {
    try {
        const result = await pool.request()
            .input("Admission_no", sql.NVarChar(10), admissionID)
            .query(`
                SELECT
                    p.Admission_no,
                    p.PatientID,
                    p.Admitted_under_care_of,
                    COALESCE(u.Name, 'Unknown') AS DoctorName,
                    p.Admission_date,
                    p.Admission_time,
                    p.Mode_of_admission,
                    p.Ward_no,
                    p.Bed_no,
                    p.Disposal_status,
                    p.Primary_diagnosis,
                    p.Associate_diagnosis,
                    p.[Procedure],
                    p.Summary,
                    p.Receiving_note
                FROM
                    PatientDetails p
                LEFT JOIN
                    Users u ON p.Admitted_under_care_of = u.UserID
                WHERE
                    p.Admission_no = @Admission_no;
            `);
        
        return result;
    } catch (error) {
        console.error("Error in fetchPatientDetails:", error.message);
        throw error;
    }
};
