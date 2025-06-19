require('dotenv').config();
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const cors = require('cors');
const db = require('./config/db'); // Database initialization
const session = require("express-session");
const checkLogin = require("./session-middleware");

const accountAccessRoutes = require("./src/routes/AccountAccessRoutes"); // import account routes
const patientRoutes = require("./src/routes/PatientInfoRoutes"); // Import registration routes
const admissionRoutes = require("./src/routes/AdmissionInfoRoutes"); // Import registration routes
const emergencyContactRoutes = require("./src/routes/EmergencyContactRoutes"); // Import registration routes
const bedRoutes = require("./src/routes/BedRoutes"); // import bed routes
const wardRoutes = require("./src/routes/WardRoutes"); // import ward routes
const doctorRoutes = require("./src/routes/DoctorRoutes"); // import doctor routes
const resendPwdSetupRoutes = require("./src/routes/ResendPwdSetupRoutes");
const setPasswordRoutes = require("./src/routes/SetPasswordRoutes");
const forgotPassword = require("./src/routes/ForgotPasswordRoutes");
const staffRoutes = require("./src/routes/StaffRoutes"); // import staff routes
const nurseRoutes = require("./src/routes/NurseRoutes"); // import nurse routes
const adminRoutes = require("./src/routes/AdminRoutes"); // import admin routes
const departmentRoutes = require("./src/routes/DepartmentRoutes"); // import department routes
const qrcodeRoutes = require("./src/routes/QRcode(for-ward)Routes"); // import qrcode routes

const bedDetailsRoutes = require("./src/routes/BedDetailsRoutes");
const consultationRoutes = require("./src/routes/ConsultationRoutes");
const dischargeRoutes = require("./src/routes/DischargeRoutes");
const prescriptionSheetRoutes = require("./src/routes/PrescriptionSheetRoutes");
const generateQrRoutes = require("./src/routes/GenerateQrRoutes");
const patientDetailRoutes = require("./src/routes/PatientDetailRoutes");
const progressRoutes = require("./src/routes/ProgressRoutes");
const userRoutes = require("./src/routes/UserRoutes");
const vitalsRoutes = require("./src/routes/VitalsRoutes");
const disposalRoutes = require("./src/routes/DisposalRoutes");
const bedStatusRoutes = require("./src/routes/BedStatusRoutes");
const nextOfKinRoutes = require("./src/routes/NextOfKinRoutes");
const drugSheetRoutes = require("./src/routes/DrugSheetRoutes");
const regenerateQrRoutes = require("./src/routes/RegenerateQrRoutes");
const uploadStatusRoutes = require("./src/routes/UploadStatusRoutes");

// Middleware to parse JSON requests and handling cors
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors({
    origin: true,
    credentials: true,          // REQUIRED for cookies
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Setup session middleware
app.use(session({
    secret: process.env.SESSION_SECRET,  // Secret key to sign the session ID
    resave: false,              // Don't save session if it wasn't modified
    saveUninitialized: false,   // Don't save a session that is not initialized
    cookie: {
        httpOnly: true,         // Ensures the cookie can't be accessed via JavaScript
        sameSite: process.env.NODE_ENV === 'production' ? 'none' : 'lax',
        secure: false,          // Set to true in production (HTTPS only)
        maxAge: 12 * 60 * 60 * 1000,
        domain: undefined
    }
}));

app.get("/api/auth/status", (req, res) => {
    if (req.session.userId) {
        return res.status(200).json({
            message: "Session is valid",
            userId: req.session.userId,
            username: req.session.username,
        });
    } else {
        return res.status(401).json({ error: "Session expired or not authenticated" });
    }
});

app.use("/api/auth", accountAccessRoutes);
app.use("/api/auth", setPasswordRoutes);
app.use("/api/auth", resendPwdSetupRoutes);
app.use("/api/auth", forgotPassword);
app.use("/api/admin", adminRoutes);

// Apply the middleware globally to all routes
app.use("/api", checkLogin);

//base URI for routes
app.use("/api/patient", patientRoutes);
app.use("/api/admission", admissionRoutes);
app.use("/api/emergency-contact", emergencyContactRoutes);
app.use("/api/bed", bedRoutes);
app.use("/api/doctor", doctorRoutes);
app.use("/api/nurse", nurseRoutes);
app.use("/api/staff", staffRoutes);
app.use("/api/department", departmentRoutes);
app.use("/api/qrcode", qrcodeRoutes);

app.use("/api/bed-details", bedDetailsRoutes);
app.use("/api/consultation-sheet", consultationRoutes);
app.use("/api/discharge", dischargeRoutes);
app.use("/api/prescription-sheet", prescriptionSheetRoutes);
app.use("/api/generateQR", generateQrRoutes);
app.use("/api/details", patientDetailRoutes);
app.use("/api/progress", progressRoutes);
app.use("/api/users", userRoutes);
app.use("/api/vitals", vitalsRoutes);
app.use("/api/ward", wardRoutes);
app.use("/api/disposal",disposalRoutes);
app.use("/api/bed-occupied-status",bedStatusRoutes);
app.use("/api/nextofkin", nextOfKinRoutes);
app.use("/api/drug-sheet", drugSheetRoutes);
app.use("/api/regenerateQR", regenerateQrRoutes);
app.use("/api/upload-to-cloud-status", uploadStatusRoutes);

// connect to the database
db.connectToDatabase()
.then(() => console.log("Database connection is ready."))
.catch(error => console.error("Failed to initialize database:", error.message));

// eg of a protected route
app.get("/api/protected", (req, res) => {
    console.log("Protected Route Session:", req.session);
    if (!req.session.userId) {
        return res.status(401).json({ error: "Unauthorized" });
    }
    res.status(200).json({ message: "Protected route", user: req.session.username });
});

// additional
app.all('*', (req, res) => {
    res.status(404).send(`Cannot ${req.method} ${req.originalUrl}`);
});

// open port to run api (start server)
var port = process.env.PORT || 8090;
app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});


