const { sql, connectToDatabase } = require("../../config/db");

const getAllDepartments = async () => {
  try {
    const pool = await connectToDatabase();
    const result = await pool.request()
        .query('SELECT DepartmentID, Department_name FROM Department ORDER BY Department_name');
    return result.recordset;
} catch (error) {
    console.error("Error fetching departments:", error);
    throw error;
  }
};

module.exports = { getAllDepartments };
