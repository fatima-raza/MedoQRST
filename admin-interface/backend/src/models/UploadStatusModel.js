const { sql } = require('../../config/db');

exports.updateUploadStatus = async (pool, admissionNo, uploadedToCloud) => {
  try {
    const result = await pool.request()
      .input("Admission_no", sql.VarChar(10), admissionNo)
      .input("Uploaded_to_cloud", sql.Bit, uploadedToCloud)
      .query(`
        UPDATE DischargeDetails
        SET Uploaded_to_cloud = @Uploaded_to_cloud
        WHERE Admission_no = @Admission_no
      `);

    return result;
  } catch (error) {
    console.error("Error in updateUploadStatus:", error.message);
    throw error;
  }
};
