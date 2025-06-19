// FOR LOCAL:
const sql = require("mssql/msnodesqlv8");

// FOR CLOUD:
// const sql = require("mssql");

const config = require("./dbconfig");

let poolPromise = null; // Store the connection pool

async function connectToDatabase() {
    if (!poolPromise) { // If there is no pool, create one
        poolPromise = sql.connect(config)
            .then(pool => {
                console.log("Connected to SQL Server!");
                return pool;
            })
            .catch(error => {
                console.error("Connection failed:", error.message);
                poolPromise = null; // Reset on failure
                throw error;
            });
    }
    return poolPromise; // Return the existing pool
}

const beginTransaction = async () => {
    const pool = await connectToDatabase();
    const transaction = new sql.Transaction(pool);
    await transaction.begin();
    return transaction;
};

module.exports = { sql, connectToDatabase, beginTransaction };
