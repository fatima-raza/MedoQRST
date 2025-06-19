const { sql, connectToDatabase } = require("../../config/db");

const createEmergencyContact = async (admission_no, name, relationship, contact_no, address) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("admission_no", sql.VarChar(20), admission_no)
            .input("name", sql.NVarChar(100), name)
            .input("relationship", sql.NVarChar(50), relationship)
            .input("contact_no", sql.VarChar(20), contact_no)
            .input("address", sql.NVarChar(200), address || null)
            .query(`
                INSERT INTO NextOfKin (Admission_no, Name, Relationship, Contact_no, Address)
                OUTPUT INSERTED.Admission_no
                VALUES (@admission_no, @name, @relationship, @contact_no, @address);
            `);

        return result.recordset[0]?.Admission_no;

    } catch (error) {
        console.error("Error saving emergency contact details:", error);
        throw error;
    }
};

// Get Emergency Contact by Admission No (Get By ID)
const getEmergencyContactByAdmissionNo = async (admission_no) => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .input("admission_no", sql.VarChar(20), admission_no)
            .query(`
                SELECT Admission_no, Name, Relationship, Contact_no, Address
                FROM NextOfKin
                WHERE Admission_no = @admission_no;
            `);

        return result.recordset[0] || null; // Return null if no record found
    } catch (error) {
        console.error("Error fetching emergency contact details:", error);
        throw error;
    }
};

// Get All Emergency Contacts
const getAllEmergencyContacts = async () => {
    try {
        const pool = await connectToDatabase();
        const result = await pool.request()
            .query(`
                SELECT Admission_no, Name, Relationship, Contact_no, Address
                FROM NextOfKin;
            `);

        return result.recordset; // Return all records as an array
    } catch (error) {
        console.error("Error fetching all emergency contact details:", error);
        throw error;
    }
};

module.exports = {
    createEmergencyContact, getEmergencyContactByAdmissionNo, getAllEmergencyContacts
};