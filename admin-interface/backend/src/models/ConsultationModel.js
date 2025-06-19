const { sql } = require("../../config/db"); // adjust path if needed

exports.fetchConsultationByadmissionID = async (pool, admissionID) => {
    const result = await pool
        .request()
        .input("Admission_no", sql.NVarChar(10), admissionID)
        .query(`
            SELECT
            P.PatientID,
            P.Admission_no,
            P.Bed_no,
            P.Ward_no,
            C.ConsultationID,
            C.Date,
            C.Time,
            C.Reason,
            C.Type_of_Comments,
            Dept1.Department_name AS Requesting_Department,
            Dept2.Department_name AS Consulting_Department,
            (SELECT Name FROM Users WHERE UserID = P.Admitted_under_care_of) AS Requesting_Doctor
            FROM PatientDetails P
            LEFT JOIN Consultation C ON P.Admission_no = C.Admission_no
            LEFT JOIN Doctor D1 ON C.Requesting_Physician = D1.DoctorID
            LEFT JOIN Doctor D2 ON C.Consulting_Physician = D2.DoctorID
            LEFT JOIN Department Dept1 ON D1.Department_ID = Dept1.DepartmentID
            LEFT JOIN Department Dept2 ON D2.Department_ID = Dept2.DepartmentID
            WHERE P.Admission_no = @Admission_no;
        `);

    return result.recordset; // same as before
};
