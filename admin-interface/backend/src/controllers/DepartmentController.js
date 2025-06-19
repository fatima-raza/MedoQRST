const departmentModel = require('../models/DepartmentModel');

const handleGetAllDepartments = async (req, res) => {
  try {
    const departments = await departmentModel.getAllDepartments();
    res.json(departments);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching departments' });
  }
};

module.exports = { handleGetAllDepartments };
