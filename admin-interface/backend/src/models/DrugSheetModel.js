const { sql } = require("../../config/db");

exports.fetchDrugSheetByAdmissionID = async (pool, admissionID) => {
    try {
        const result = await pool
            .request()
            .input("Admission_no", sql.NVarChar(10), admissionID)
            .query(`
                SELECT 
                    m.Admission_no, 
                    m.Record_ID, 
                    m.Drug_ID, 
                    d.Commercial_name, 
                    d.Generic_name, 
                    d.Strength, 
                    m.Date, 
                    m.Time, 
                    m.Monitored_By, 
                    m.Dosage, 
                    m.Shift
                FROM MedicationRecord m
                INNER JOIN Drug d ON m.Drug_ID = d.DrugID
                WHERE m.Admission_no = @Admission_no;
            `);

        return result.recordset;
    } catch (error) {
        console.error("❌ Error in fetchDrugSheetByAdmissionID:", error.message);
        throw error;
    }
};
