const { sql } = require('../../config/db');

exports.fetchProgressNotes = async (pool, admissionID) => {
    try {
        const result = await pool.request()
            .input("Admission_no", sql.NVarChar(10), admissionID)
        
            .query(`
                SELECT
                    Pr.Progress_Date,
                    ISNULL(U.Name, 'Unknown Doctor') AS Doctor,
                    Pr.Notes,
                    pr.Admission_no
                FROM Progress Pr
                LEFT JOIN Users U ON Pr.Reported_By = U.UserID
                WHERE Pr.Admission_no = @Admission_no
                ORDER BY Pr.Progress_Date DESC;
            `);

        return result;
    } catch (error) {
        console.error("Error in fetchProgressNotes:", error.message);
        throw error;
    }
};
