const { sql } = require("../../config/db");

exports.generateQR = async (pool, wardNo, isSingleBed, count) => {
    const request = pool.request();

    if (isSingleBed) {
        await request.query(`INSERT INTO QRcode (Assigned_to) VALUES ('Bed');`);

        const qrResult = await pool
            .request()
            .query(`SELECT TOP 1 qrID FROM QRcode ORDER BY qrID DESC;`);
        const qrID = qrResult.recordset[0]?.qrID;

        await pool
            .request()
            .input("qrID", sql.Int, qrID)
            .input("wardNo", sql.VarChar, wardNo)
            .query(`INSERT INTO Bed (QRcode, Ward_no) VALUES (@qrID, @wardNo);`);

        const bedResult = await pool
            .request()
            .input("qrID", sql.Int, qrID)
            .query(`SELECT TOP 1 Bed_no FROM Bed WHERE QRcode = @qrID ORDER BY Bed_no DESC;`);

        const bedNo = bedResult.recordset[0]?.Bed_no;

        return { qrId: qrID, bedNo ,wardNo};
    }

    // Multiple beds logic
    const insertValues = Array(count).fill("('Bed')").join(", ");
    await pool.request().query(`INSERT INTO QRcode (Assigned_to) VALUES ${insertValues};`);

    const qrResults = await pool
        .request()
        .query(`SELECT TOP ${count} qrID FROM QRcode ORDER BY qrID DESC;`);
    const idsList = qrResults.recordset.map(row => row.qrID).reverse();

    const bedInsertValues = idsList.map(qrID => `(${qrID}, '${wardNo}')`).join(", ");
    await pool.request().query(`INSERT INTO Bed (QRcode, Ward_no) VALUES ${bedInsertValues};`);

    const qrIDListForQuery = idsList.join(", ");
    const bedResults = await pool
        .request()
        .query(`SELECT Bed_no,Ward_no, QRcode FROM Bed WHERE QRcode IN (${qrIDListForQuery});`);

    return {
        beds: bedResults.recordset.map(row => ({
            qrId: row.QRcode,
            bedNo: row.Bed_no,
            wardNo: row.Ward_no
        }))
    };
};
