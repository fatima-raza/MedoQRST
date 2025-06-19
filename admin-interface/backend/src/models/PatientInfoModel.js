const { sql, connectToDatabase } = require("../../config/db");

const createPatient = async (name, age, gender, contact_number, cnic, address) => {
    try {
        const pool = await connectToDatabase();
        await pool.request()
            .input("name", sql.NVarChar, name)
            .input("age", sql.Int, age)
            .input("gender", sql.Char(1), gender)
            .input("contact_number", sql.NVarChar, contact_number || null)
            .input("cnic", sql.Char(13), cnic)
            .input("address", sql.NVarChar, address || null)
            .input("role", sql.NVarChar, "Patient")
            .query(`
                INSERT INTO Users (Name, Age, Gender, Contact_number, CNIC, Address, Role)
                VALUES (@name, @age, @gender, @contact_number, @cnic, @address, @role);
            `);

        // Capture the newly inserted UserID directly via cnic no.
        const result = await pool.request()
            .input("cnic", sql.Char(13), cnic)
            .query(`
                SELECT UserID AS PatientID FROM Users WHERE CNIC = @cnic AND Role = 'Patient';
            `);

        const patientId = result.recordset[0]?.PatientID;

        if (!patientId) {
            throw new Error("Failed to retrieve the generated PatientID.");
        }

        return patientId;

    } catch (error) {
        console.error("Error adding patient:", error);
        throw error;
    }
};

const getPatientById = async (patientId) => {
    try {
        console.log("Searching by ID:", patientId);  // Log ID value

        const pool = await connectToDatabase();

        // Quick test query to ensure connection is working
        const testResult = await pool.request().query("SELECT COUNT(*) AS total FROM Users");
        console.log("Total Users:", testResult.recordset[0].total);

        const result = await pool
            .request()
            .input("patientId", sql.NVarChar, patientId.trim())
            .query(`
                SELECT UserID, Name, Age, Gender, Contact_number, CNIC, Address
                FROM Users
                WHERE UserID = @patientId AND Role = 'Patient'
            `);

        console.log("Query Result:", result.recordset); // Debug log

        return result.recordset[0] || null;
    } catch (error) {
        console.error("Error fetching patient:", error);
        throw error;
    }
};

const getPatientByCNIC = async (cnic) => {
    try {
        const pool = await connectToDatabase();

        const result = await pool.request()
            .input("cnic", sql.Char(13), cnic.trim())
            .query(`
                SELECT UserID, Name, Age, Gender, Contact_number, CNIC, Address
                FROM Users
                WHERE CNIC = @cnic AND Role = 'Patient'
            `);

        console.log('query result: ', result.recordset);
        
        return result.recordset[0] || null;
    } catch (error) {
        console.error("Error in getPatientByCNIC:", error);
        throw error;
    }
};

const getAllPatients = async () => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request().query(`
            SELECT UserID, Name, Age, Gender, Contact_number, CNIC, Address
            FROM Users
            WHERE Role = 'Patient'
        `);
        return result.recordset;
    } catch (error) {
        console.error("Error fetching all patients:", error);
        throw error;
    }
};

const updatePatient = async (patientId, fieldsToUpdate) => {
    try {
        const pool = await connectToDatabase();

        // Dynamically build the SET clause based on provided fields
        const setClauses = [];
        const request = pool.request();

        // Always add the patientId
        request.input("patientId", sql.NVarChar, patientId);

        // Dynamically add only provided fields
        for (const [key, value] of Object.entries(fieldsToUpdate)) {
            if (value !== undefined && value !== null) {
                setClauses.push(`${key} = @${key}`);
                request.input(key, value);
            }
        }

        if (setClauses.length === 0) {
            return { error: "No valid fields provided for update." };
        }

        // final query construction
        const query = `
            UPDATE Users
            SET ${setClauses.join(", ")}
            WHERE UserID = @patientId AND Role = 'Patient'
        `;

        // Return the raw result for detailed checks
        return await request.query(query);
    } catch (error) {
        console.error("Error updating patient:", error);
        throw error;
    }
};

const deletePatient = async (patientId) => {
    try {
        const pool = await connectToDatabase();
        return await pool.request()
            .input("patientId", sql.NVarChar, patientId)
            .query("DELETE FROM Users WHERE UserID = @patientId AND Role = 'Patient'");
    } catch (error) {
        console.error("Error deleting patient:", error);
        throw error;
    }
};


module.exports = { createPatient, getPatientById, getPatientByCNIC, getAllPatients, updatePatient, deletePatient };
