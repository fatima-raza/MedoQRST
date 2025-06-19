const { sql } = require("../../config/db");

exports.fetchDischargeDetailsByadmissionID = async (pool, admissionID) => {
    const result = await pool
        .request()
        .input("Admission_no", sql.NVarChar(10), admissionID)
        .query(`
            SELECT
                p.PatientID,
                d.Admission_no,
                d.Doctor_id,
                d.Discharge_date,
                d.Discharge_time,
                d.Surgery,
                d.Operative_findings,
                d.Examination_findings,
                d.Discharge_treatment,
                d.Follow_up,
                d.Instructions,
                d.Condition_at_discharge,
                r.CT_scan,
                r.MRI,
                r.Biopsy,
                r.Other_reports
            FROM PatientDetails p
            INNER JOIN DischargeDetails d ON p.Admission_no = d.Admission_no
            INNER JOIN DiagnosticReports r ON d.Admission_no = r.Admission_no
            WHERE p.Admission_no = @Admission_no
        `);

    return result.recordset;
};
