const { sql } = require("../../config/db");

exports.fetchPrescriptionSheetByadmissionID = async (pool, admissionID) => {
    try {
        const result = await pool
            .request()
            .input("Admission_no", sql.NVarChar(10), admissionID)
           
            .query(`
                SELECT
    p.Admission_no,
    p.Record_ID,
    p.Drug_ID,
    u.Name AS Doctor_Name, 
    p.Dosage,
    p.Medication_Status,
    d.Commercial_name,
    d.Generic_name,
    d.Strength
FROM 
    Prescription p
INNER JOIN 
    Drug d ON p.Drug_ID = d.DrugID
INNER JOIN 
    [Users] u ON p.Prescribed_by = u.UserID 
WHERE 
    p.Admission_no = @Admission_no;
            `);

        return result.recordset;
    } catch (error) {
        console.error("❌ Error in fetchPrescriptionSheetByadmissionID:", error.message);
        throw error;
    }
};