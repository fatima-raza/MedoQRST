// const { sql } = require('../../config/db');

// exports.fetchUserDetails = async (pool, admissionID) => {
//     try {
//         const result = await pool.request()
//             .input("Admission_no", sql.NVarChar(10), admissionID)
//             // .query(`
//             //     SELECT u.*
//             //     FROM Users u
//             //     JOIN PatientDetails p ON u.UserID = p.PatientID
//             //     WHERE p.Admission_no = @Admission_no
//             // `);
//              .query(`
//                  SELECT 
//                     u.*, 
//                     p.Disposal_status, 
//                     d.Uploaded_to_cloud
//                 FROM Users u
//                 JOIN PatientDetails p ON u.UserID = p.PatientID
//                 LEFT JOIN DischargeDetails d ON p.Admission_no = d.Admission_no
//                 WHERE p.Admission_no = @Admission_no
//             `);

//         return result;
//     } catch (error) {
//         console.error("Error in fetchUserDetails:", error.message);
//         throw error;
//     }
// };


const { sql } = require('../../config/db');

exports.fetchUserDetails = async (pool, admissionID) => {
    try {
        const result = await pool.request()
            .input("Admission_no", sql.NVarChar(10), admissionID)
            .query(`
                SELECT p.Admission_no, p.Disposal_status, d.Uploaded_to_cloud, u.*
                FROM Users u
                JOIN PatientDetails p ON u.UserID = p.PatientID
                LEFT JOIN DischargeDetails d ON p.Admission_no = d.Admission_no
                WHERE p.Admission_no = @Admission_no
            `);

        return result;
    } catch (error) {
        console.error("Error in fetchUserDetails:", error.message);
        throw error;
    }
};
