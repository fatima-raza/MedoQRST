const { sql, connectToDatabase } = require("../../config/db");

const createAdmissionInfo = async (patientId, dateOfAdmission, timeOfAdmission, modeOfAdmission, wardNo, bedNo, admittedUnderCareOf) => {
    try {
        const pool = await connectToDatabase();

        // Check if the ward number exists
        const wardCheck = await pool.request()
            .input("wardNo", sql.Char(3), wardNo)
            .query("SELECT 1 FROM Ward WHERE Ward_no = @wardNo");

        if (!wardCheck.recordset.length) {
            throw new Error("Invalid Ward Number");
        }

        // Check if the ward and bed exist together and are available
        const bedCheck = await pool.request()
            .input("wardNo", sql.Char(3), wardNo)
            .input("bedNo", sql.Int, bedNo)
            .query("SELECT is_occupied FROM Bed WHERE Bed_no = @bedNo AND Ward_no = @wardNo");

        if (!bedCheck.recordset.length) {
            throw new Error("Invalid Bed/Ward Combination");
        }

        if (bedCheck.recordset[0].is_occupied) {
            throw new Error("Bed is already occupied");
        }

        // Check if the doctor exists
        const doctorCheck = await pool.request()
            .input("doctorId", sql.NVarChar, admittedUnderCareOf)
            .query("SELECT 1 FROM Doctor WHERE DoctorID = @doctorId");

        if (!doctorCheck.recordset.length) {
            throw new Error("Invalid Doctor ID");
        }

        console.log("Received Admission Data:", {
            patientId,
            dateOfAdmission,
            timeOfAdmission,
            modeOfAdmission,
            wardNo,
            bedNo,
            admittedUnderCareOf
        });
        

        const result = await pool.request()
            .input("patientId", sql.NVarChar, patientId)
            .input("dateOfAdmission", sql.Date, dateOfAdmission)
            .input("timeOfAdmission", sql.NVarChar, timeOfAdmission)
            .input("modeOfAdmission", sql.NVarChar, modeOfAdmission)
            .input("wardNo", sql.Char(3), wardNo)
            .input("bedNo", sql.Int, bedNo)
            .input("admittedUnderCareOf", sql.NVarChar, admittedUnderCareOf)
            .query(`
                INSERT INTO PatientDetails (PatientID, Admission_date, Admission_time, Mode_of_admission, Ward_no, Bed_no, Admitted_under_care_of)
                OUTPUT INSERTED.Admission_no
                VALUES (@patientId, @dateOfAdmission, @timeOfAdmission, @modeOfAdmission, @wardNo, @bedNo, @admittedUnderCareOf)
            `);

        // Update bed status to occupied
        await pool.request()
            .input("wardNo", sql.Char(3), wardNo)
            .input("bedNo", sql.Int, bedNo)
            .query("UPDATE Bed SET is_occupied = 1 WHERE Ward_no = @wardNo AND Bed_no = @bedNo");

        return result.recordset[0].Admission_no;  // Return the generated Admission_no

    } catch (error) {
        console.error("Error adding admission info:", error);
        throw error;
    }
};

const getAdmissionById = async (admissionNo) => {
    try {
        const pool = await connectToDatabase();

        const result = await pool.request()
            .input("admissionNo", sql.NVarChar, admissionNo)
            .query(`
                SELECT
                    Admission_no, PatientID, Admission_date, Admission_time, Mode_of_admission, 
                    Ward_no, Bed_no, Admitted_under_care_of
                FROM PatientDetails
                WHERE Admission_no = @admissionNo
            `);

        if (result.recordset.length === 0) {
            return null;
        }

        return result.recordset[0];

    } catch (error) {
        console.error("Error fetching admission info:", error);
        throw error;
    }
};

const getAllAdmissions = async () => {
    try {
        const pool = await connectToDatabase();

        const result = await pool.request().query(`
            SELECT Admission_no, PatientID, Admission_date, Admission_time, Mode_of_admission, Ward_no, Bed_no, Admitted_under_care_of 
            FROM PatientDetails
        `);

        return result.recordset; // Return all admissions

    } catch (error) {
        console.error("Error fetching all admissions:", error);
        throw error;
    }
};

const updateAdmissionInfo = async (admissionNo, patientId, dateOfAdmission, modeOfAdmission, wardNo, bedNo, admittedUnderCareOf) => {
    try {
        const pool = await connectToDatabase();

        // Check if the ward number exists
        const wardCheck = await pool.request()
            .input("wardNo", sql.Char(3), wardNo)
            .query("SELECT 1 FROM Ward WHERE Ward_no = @wardNo");

        if (!wardCheck.recordset.length) {
            throw new Error("Invalid Ward Number");
        }

        // Check if the ward and bed exist together and are available
        const bedCheck = await pool.request()
            .input("wardNo", sql.Char(3), wardNo)
            .input("bedNo", sql.Int, bedNo)
            .query("SELECT is_occupied FROM Bed WHERE Bed_no = @bedNo AND Ward_no = @wardNo");

        if (!bedCheck.recordset.length) {
            throw new Error("Invalid Bed/Ward Combination");
        }

        if (bedCheck.recordset[0].is_occupied) {
            throw new Error("Bed is already occupied");
        }

        // Check if the doctor exists
        const doctorCheck = await pool.request()
            .input("doctorId", sql.NVarChar, admittedUnderCareOf)
            .query("SELECT 1 FROM Doctor WHERE DoctorID = @doctorId");

        if (!doctorCheck.recordset.length) {
            throw new Error("Invalid Doctor ID");
        }

        const result = await pool.request()
            .input("admissionNo", sql.NVarChar, admissionNo)
            .input("patientId", sql.NVarChar, patientId)
            .input("dateOfAdmission", sql.Date, dateOfAdmission)
            .input("modeOfAdmission", sql.NVarChar, modeOfAdmission)
            .input("wardNo", sql.Char(3), wardNo)
            .input("bedNo", sql.Int, bedNo)
            .input("admittedUnderCareOf", sql.NVarChar, admittedUnderCareOf)
            .query(`
                UPDATE PatientDetails
                SET PatientID = @patientId,
                    Admission_date = @dateOfAdmission,
                    Mode_of_admission = @modeOfAdmission,
                    Ward_no = @wardNo,
                    Bed_no = @bedNo,
                    Admitted_under_care_of = @admittedUnderCareOf
                WHERE Admission_no = @admissionNo
            `);

        // Update bed status to occupied
        await pool.request()
            .input("wardNo", sql.Char(3), wardNo)
            .input("bedNo", sql.Int, bedNo)
            .query("UPDATE Bed SET is_occupied = 1 WHERE Ward_no = @wardNo AND Bed_no = @bedNo");

        return result.rowsAffected[0] > 0;

    } catch (error) {
        console.error("Error updating admission info:", error);
        throw error;
    }
};

const deleteAdmissionInfo = async (admissionNo) => {
    try {
        const pool = await connectToDatabase();

        const result = await pool.request()
            .input("admissionNo", sql.NVarChar, admissionNo)
            .query("DELETE FROM PatientDetails WHERE Admission_no = @admissionNo");

        return result.rowsAffected[0] > 0;  // Return true if a row was deleted

    } catch (error) {
        console.error("Error deleting admission info:", error);
        throw error;
    }
};


module.exports = { createAdmissionInfo, getAdmissionById, getAllAdmissions, updateAdmissionInfo, deleteAdmissionInfo };
