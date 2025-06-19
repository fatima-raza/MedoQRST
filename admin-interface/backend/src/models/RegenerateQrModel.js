const { sql } = require("../../config/db");

exports.regenerateQR = async (pool, wardNo, bedNo) => {
  const request = pool.request();

  // Step 1: Find existing QR ID for the given wardNo and bedNo
  const existingQR = await request
    .input("wardNo", sql.VarChar, wardNo)
    .input("bedNo", sql.Int, bedNo)
    .query(`
      SELECT QRcode FROM Bed WHERE Ward_no = @wardNo AND Bed_no = @bedNo;
    `);

  if (existingQR.recordset.length === 0) {
    throw new Error("No existing bed found with the given wardNo and bedNo.");
  }

  const oldQrId = existingQR.recordset[0].QRcode;

  // Step 2: Mark old QR as inactive
  await pool.request()
    .input("oldQrId", sql.Int, oldQrId)
    .query(`
      UPDATE QRcode SET Status = 'inactive' WHERE qrID = @oldQrId;
    `);

  // Step 3: Generate new QR
  await pool.request().query(`INSERT INTO QRcode (Assigned_to) VALUES ('Bed');`);

  const qrResult = await pool
    .request()
    .query(`SELECT TOP 1 qrID FROM QRcode ORDER BY qrID DESC;`);
  const newQrId = qrResult.recordset[0].qrID;

  // Step 4: Update Bed table with new QRcode
  await pool.request()
    .input("wardNo", sql.VarChar, wardNo)
    .input("bedNo", sql.Int, bedNo)
    .input("newQrId", sql.Int, newQrId)
    .query(`
      UPDATE Bed SET QRcode = @newQrId WHERE Ward_no = @wardNo AND Bed_no = @bedNo;
    `);

  // Optional: Return updated data
  return {
    qrId: newQrId,
    bedNo: parseInt(bedNo),
    wardNo: wardNo
  };
};
