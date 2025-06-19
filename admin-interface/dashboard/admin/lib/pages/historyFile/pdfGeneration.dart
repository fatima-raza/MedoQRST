import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../utils/date_time_utils.dart';
import '../../services/google_drive_services.dart';
import '../../services/users_services.dart';

class PdfGenerator {
  final String subFolderPath;

  PdfGenerator(this.subFolderPath);

  // Define Main Heading color (blue)
  static final mainHeadingStyle = pw.TextStyle(
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
    color: PdfColor.fromHex('#00008C'),
  );

  final pw.TextStyle sectionHeaderStyle = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  String getFirstName(String fullName) {
    // Split the full name by spaces and return the first part (first name)
    return fullName.split(' ').first;
  }

  pw.Widget buildPageNumber(pw.Context context, {pw.Font? font}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          'Page ${context.pageNumber}',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            font: font,
          ),
        ),
      ],
    );
  }



// Function to parse and format date string (e.g. from DB) to dd-MM-yyyy
  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return formatDateCompact(parsedDate); // From date_time_utils.dart
    } catch (e) {
      return date; // fallback if parsing fails
    }
  }



  String formatTimeFromString(String time) {
    try {
      print('Received time: $time');

      // Parse as ISO string directly
      final parsedTime = DateTime.parse(time);

      // Format only time part
      return DateFormat('hh:mm a').format(parsedTime); // or 'HH:mm' for 24-hour
    } catch (e) {
      print('Error parsing time: $time | Error: $e');
      return 'Invalid Time';
    }
  }

  pw.Widget buildSectionHeading(String text, {pw.Font? font}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      color: PdfColors.blueGrey200,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800, // Matches deep grey/black tone
          font: font,
        ),
      ),
    );
  }


  List<pw.Widget> _buildConsultationBody(Map<String, dynamic> data,
      {required pw.Font font}) {
    final List<dynamic> consultations = data['data'] ?? [];
    print('Consultation List {$consultations}');

    if (consultations.isEmpty) {
      return [
        pw.Text('No consultation data found.', style: pw.TextStyle(font: font))
      ];
    }

    return List.generate(consultations.length, (index) {
      final item = consultations[index] as Map<String, dynamic>;

      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 20),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text(
                'Consultation ID: ${item['ConsultationID'] ?? 'Unknown'}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.Text(
              'Consultation Type: ${item['Type_of_Comments'] ?? 'Unknown'}',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.SizedBox(height: 6),

            // Consultation Info Table
            pw.Table(
              border: pw.TableBorder.all(
                width: 1,
                color: PdfColor.fromInt(0xFF808080),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.5),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _tableCell('S.N.', font),
                    _tableCell('Requesting Dept', font),
                    _tableCell('Consulting Dept', font),
                    _tableCell('Date', font),
                    _tableCell('Time', font),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _tableCell('${index + 1}', font),
                    _tableCell(
                        item['Requesting_Department'] ?? 'Unknown', font),
                    _tableCell(
                        item['Consulting_Department'] ?? 'Unknown', font),
                    _tableCell(formatDate(item['Date'] ?? ''), font),
                    _tableCell(formatTimeFromString(item['Time'] ?? ''), font),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Reason for Consultancy
            pw.Text(
              'Reason for Consultancy:',
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey, width: 0.8),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                item['Reason'] ?? 'No reason provided.',
                style: pw.TextStyle(font: font, fontSize: 10),
                softWrap: true,
              ),
            ),
            pw.SizedBox(height: 14),

            // Requesting Doctor & Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Requesting Doctor: Dr. ${item['Requesting_Doctor'] ?? 'Unknown'}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  'Signature: __________________',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColor.fromInt(0xFF808080), thickness: 1),
            pw.SizedBox(height: 10),
          ],
        ),
      );
    });
  }

  pw.Widget _tableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
      ),
    );
  }

  Future<bool> generatePdf(
    Map<String, dynamic> userData,
    Map<String, dynamic> registrationSheetData,
    Map<String, dynamic> nextOfKinData,
    Map<String, dynamic> consultationSheetData,
    Map<String, dynamic> prescriptionSheetData,
    Map<String, dynamic> progressReportData,
    Map<String, dynamic> dischargeSheetData,
    Map<String, dynamic> receivingNotes,
    Map<String, dynamic> drugSheetData,
  ) async {
    print('Consultation Sheet Data Received: ${consultationSheetData}');
    // print('Next of Kin DAta: ${nextOfKinData}');
    final pdf = pw.Document();
    final notoFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));

//     // // Destructure user data
    final patientID = userData['UserID'] ?? 'Unknown';
    final patientName = userData['Name'] ?? 'Unknown';
    final contactNumber = userData['Contact_number'] ?? 'Unknown';
    final alternateContactNumber =
        userData['Alternate_contact_number'] ?? 'Unknown';
    final address = userData['Address'] ?? 'Unknown';
    final age = userData['Age'] ?? 'Unknown';
    final gender = userData['Gender'] ?? 'Unknown';
    final CNIC = userData['CNIC'] ?? '-';

    // Destructure registration sheet data
    final admissionNo = registrationSheetData['Admission_no'] ?? 'Unknown';
    final doctorName = registrationSheetData['DoctorName'] ?? 'Unknown';
    final doctorId =
        registrationSheetData['Admitted_under_care_of'] ?? 'Unknown'; //not used
    final wardNo = registrationSheetData['Ward_no'] ?? 'Unknown';
    final bedNo = registrationSheetData['Bed_no'] ?? 'Unknown';
    final primaryDiagnosis =
        registrationSheetData['Primary_diagnosis'] ?? 'Unknown';
    final associateDiagnosis =
        registrationSheetData['Associate_diagnosis'] ?? 'Unknown';
    final procedure =
        registrationSheetData['Procedure'] ?? 'Unknown'; //not used
    final summary = registrationSheetData['Summary'] ?? 'Unknown'; //not  used
    final receivingNote = registrationSheetData['Receiving_note'] ?? 'Unknown';
    final modeOfAdmission =
        registrationSheetData['Mode_of_admission'] ?? 'Unknown';

    final kin = nextOfKinData['data'][0];

    // 👉 Admission Date + Time Formatting
    final admissionDate = registrationSheetData['Admission_date'] ?? 'Unknown';
    final admissionTime =
        registrationSheetData['Admission_time'] ?? '00:00:00.000000';

  
    final formattedAdmissionDateTime =
        getFormattedDateTime(admissionDate, admissionTime);

 

    // Initialize variables with default values
    String dischargeDate = 'Unknown';
    String dischargeTime = 'Unknown';
    String surgeryDetails = 'Not applicable';
    String operativeFindings = 'Not available';
    String examinationFindings = 'Not available'; //not used
    String dischargeTreatment = 'Not available';
    String followUp = 'Not available';
    String instructions = 'Not available';
    String conditionAtDischarge = 'Not available';
    String CTScan = 'Not available';
    String MRI = 'Not available';
    String biopsyReport = 'Not available';
    String otherFindings = 'Not available';

// Get the first discharge record from the data
    List<Map<String, dynamic>> dischargeDetails =
        List<Map<String, dynamic>>.from(dischargeSheetData['data'] ?? []);

    final firstDischarge =
        dischargeDetails.isNotEmpty ? dischargeDetails.first : null;

    if (firstDischarge != null) {
      dischargeDate = firstDischarge['Discharge_date'] ?? 'Unknown';
      dischargeTime = firstDischarge['Discharge_time'] ?? 'Unknown';

      // final formattedDischargeDateTime =
      //   getFormattedDateTime(dischargeDate, dischargeTime);

      surgeryDetails = firstDischarge['Surgery'] ?? 'Not applicable';
      operativeFindings =
          firstDischarge['Operative_findings'] ?? 'Not available';
      examinationFindings =
          firstDischarge['Examination_findings'] ?? 'Not available';
      dischargeTreatment =
          firstDischarge['Discharge_treatment'] ?? 'Not available';
      followUp = firstDischarge['Follow_up'] ?? 'Not available';
      instructions = firstDischarge['Instructions'] ?? 'Not available';
      conditionAtDischarge =
          firstDischarge['Condition_at_discharge'] ?? 'Not available';
      CTScan = firstDischarge['CT_scan'] ?? 'Not available';
      MRI = firstDischarge['MRI'] ?? 'Not available';
      biopsyReport = firstDischarge['Biopsy'] ?? 'Not available';
      otherFindings = firstDischarge['Other_reports'] ?? 'Not available';
    }

    //Receiving Notes/ Vitals

    final vitalsData = receivingNotes['data'] != null &&
            receivingNotes['data'] is List &&
            receivingNotes['data'].isNotEmpty
        ? receivingNotes['data'][0]
        : {};

    final BP = vitalsData['Blood_pressure'] ?? 'Unknown'; // Already string

    final RR = vitalsData['Respiration_rate'] != null
        ? '${vitalsData['Respiration_rate']} breaths/min'
        : 'Unknown';

    final PR = vitalsData['Pulse_rate'] != null
        ? '${vitalsData['Pulse_rate']} bpm'
        : 'Unknown';

    final OS = vitalsData['Oxygen_saturation'] != null
        ? '${vitalsData['Oxygen_saturation'].toStringAsFixed(1)} %'
        : 'Unknown';

    final Temperature = vitalsData['Temperature'] != null
        ? '${vitalsData['Temperature'].toStringAsFixed(1)} °F'
        : 'Unknown';

    final RBS = vitalsData['Random_blood_sugar'] != null
        ? '${vitalsData['Random_blood_sugar'].toStringAsFixed(1)} mg/dL'
        : 'Unknown';

    // 👉 Current Date
    final now = DateTime.now();
    final formattedDate = "${_getMonthName(now.month)} ${now.day}, ${now.year}";

    /// Footer widget
    pw.Widget footer = pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // Divider line
        pw.Divider(
          thickness: 1,
          color: PdfColor.fromHex('00008C'), // Deep blue divider
        ),
        // Footer text
        pw.Container(
          height: 50,
          alignment: pw.Alignment.center,
          child: pw.Text(
            'Document Generated By MedoQRST | $formattedDate',
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey800, // Matches subtext color
              font: notoFont,
            ),
          ),
        ),
      ],
    );

    pw.Widget buildMainHeading(String headingText) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Main Heading Text
          pw.Text(
            headingText,
            style: pw.TextStyle(
              fontSize: 16, // Adjust font size as needed
              fontWeight: pw.FontWeight.bold,
              font: notoFont, // Apply custom font here
              color: PdfColor.fromHex(
                  '#00008C'), // Optional: Set color for heading text
            ),
          ),
          // Divider line for the main heading
          pw.Divider(
            thickness: 1,
            color: PdfColor.fromHex('#00008C'), // Blue color for the divider
          ),
          pw.SizedBox(height: 10), // Optional spacing after the heading
        ],
      );
    }

    pw.TableRow buildVitalsRow(String label, String value) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      );
    }

//     //pdf pages from here

    // //Title Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Horizontal header strip (reduced thickness)
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.Container(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MedoQRST',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('00008C'), // Deep Blue
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Organized record, simplified access',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey800, // Subtle gray
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Divider(
                        thickness: 1,
                        color: PdfColor.fromHex('00008C'), // Deep blue divider
                      ),
                      pw.SizedBox(
                          height: 10), // Space after divider before body starts
                    ],
                  ),
                ),
              ),

              // Footer to be stuck at the bottom of the page
              pw.Align(
                alignment: pw.Alignment.bottomCenter,
                child: footer, // Your footer widget
              ), // Footer for this page

              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      // Main Title
                      pw.Text(
                        'Medical History File',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color:
                              PdfColor.fromHex('424242'), // Dark grey for title
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 20),

                      // Patient Details Box (with No Rounded Corners)
                      pw.Container(
                        padding: const pw.EdgeInsets.all(15),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey300, // Soft grey border
                            width: 1.5,
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Patient Name: $patientName',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    pw.FontWeight.normal, // Bold for emphasis
                                color: PdfColors.grey800, // Grey color for text
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'Patient ID: $patientID',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.normal,
                                color: PdfColors.grey800, // Grey color for text
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'Treated by: Dr. $doctorName',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.normal,
                                color: PdfColors.grey800, // Grey color for text
                              ),
                            ),
                            pw.SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

// // //Registration Sheet

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Page Number - Top Right
              pw.Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: buildPageNumber(context, font: notoFont),
              ),

              // Main content with enough padding to avoid footer overlap
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(
                    top: 40,
                    left: 30,
                    right: 30,
                    bottom: 120,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      buildMainHeading('Registration Sheet'),

                      pw.SizedBox(height: 10),

                      // Patient Information
                      buildSectionHeading('Patient Information',
                          font: notoFont),

                      pw.Text('Name: $patientName',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text('ID: $patientID',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text('Age: $age',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text('Gender: $gender',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text('CNIC: $CNIC',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text(
                        'Phone No: $contactNumber | $alternateContactNumber',
                        style: pw.TextStyle(fontSize: 12, font: notoFont),
                      ),
                      pw.Text('Address: $address',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),

                      // Registration Info
                      pw.SizedBox(height: 15),
                      buildSectionHeading('Registration Information',
                          font: notoFont),

                      pw.Text('Admission No: $admissionNo',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text('Mode of Admission: $modeOfAdmission',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text(
                        'Admitted Date & Time: ${formattedAdmissionDateTime['date']}| ${formattedAdmissionDateTime['time']}',
                        style: pw.TextStyle(fontSize: 12, font: notoFont),
                      ),
                      pw.Text('Ward No/ Bed No: $wardNo/$bedNo',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),

                      // Contact Info
                      pw.SizedBox(height: 15),
                      buildSectionHeading('Contact Information',
                          font: notoFont),

                      pw.Text('Next of Kin to Inform: ${kin['Name']}',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text('Relation with Patient: ${kin['Relationship']}',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),
                      pw.Text('Emergency Contact: ${kin['Contact_no']}',
                          style: pw.TextStyle(fontSize: 12, font: notoFont)),

                      pw.SizedBox(height: 40),

                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Admitted under: Dr. $doctorName',
                              style: pw.TextStyle(
                                fontSize: 12,
                                font: notoFont,
                                color: PdfColors.grey700, // Dull grey color
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Signature: ____________',
                              style: pw.TextStyle(
                                fontSize: 12,
                                font: notoFont,
                                color: PdfColors.grey700, // Dull grey color
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer fixed at bottom center
              pw.Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: pw.Align(
                  alignment: pw.Alignment.center,
                  child: footer,
                ),
              ),
            ],
          );
        },
      ),
    );

// //Receiving Notes
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        // Repeating Header
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildMainHeading('Receiving Notes'),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => footer,

        build: (context) => [
          // Section 1: Admission Condition
          buildSectionHeading('Admitted Condition'),
          pw.Text(
            receivingNote,
            style: pw.TextStyle(fontSize: 12, font: notoFont),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 20),

          // Section 2: Diagnostic Details
          buildSectionHeading('Diagnostic Details'),
          pw.SizedBox(height: 8),
          // Primary Diagnosis
          if (primaryDiagnosis.contains(',')) ...[
            pw.Text(
              'Primary Diagnosis:',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, font: notoFont),
            ),
            ...primaryDiagnosis.split(',').map((diag) => pw.Bullet(
                  text: diag.trim(),
                  style: pw.TextStyle(fontSize: 12, font: notoFont),
                ))
          ] else
            pw.RichText(
              text: pw.TextSpan(
                text: 'Primary Diagnosis: ',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: notoFont),
                children: [
                  pw.TextSpan(
                    text: primaryDiagnosis.trim(),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.normal, font: notoFont),
                  )
                ],
              ),
            ),

          pw.SizedBox(height: 10),

          // Associated Diagnosis
          if (associateDiagnosis.contains(',')) ...[
            pw.Text(
              'Associated Diagnosis:',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, font: notoFont),
            ),
            ...associateDiagnosis.split(',').map((diag) => pw.Bullet(
                  text: diag.trim(),
                  style: pw.TextStyle(fontSize: 12, font: notoFont),
                ))
          ] else
            pw.RichText(
              text: pw.TextSpan(
                text: 'Associated Diagnosis: ',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: notoFont),
                children: [
                  pw.TextSpan(
                    text: associateDiagnosis.trim(),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.normal, font: notoFont),
                  )
                ],
              ),
            ),

          pw.Wrap(
            crossAxisAlignment: pw.WrapCrossAlignment.start,
            children: [
              buildSectionHeading('Patient Vitals'),
              pw.SizedBox(height: 8),
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  buildVitalsRow('Blood Pressure (BP)', BP),
                  buildVitalsRow('Respiration Rate (RR)', RR),
                  buildVitalsRow('Pulse Rate (PR)', PR),
                  buildVitalsRow('Oxygen Saturation (SpO2)', OS),
                  buildVitalsRow('Temperature', Temperature),
                  buildVitalsRow('Random Blood Sugar (RBS)', RBS),
                ],
              ),
              // Added Padding for spacing between table and "Admitted on" text
              pw.Padding(
                padding: const pw.EdgeInsets.only(
                    top: 20), // Add space before the "Admitted on" text
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Admitted on: ${formattedAdmissionDateTime['date']} | ${formattedAdmissionDateTime['time']}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      font: notoFont,
                      color:
                          PdfColors.grey700, // Match other right-aligned styles
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

// // Prescription Sheet
    final List<dynamic> prescriptionData = prescriptionSheetData['data'] ?? [];

    if (prescriptionData.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final headerStyle = pw.TextStyle(
              font: notoFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            );

            final cellStyle = pw.TextStyle(
              font: notoFont,
              fontSize: 11,
            );

            return pw.Stack(
              children: [
                // Page Number at the top
                pw.Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: buildPageNumber(context, font: notoFont),
                ),

                pw.Padding(
                  padding: const pw.EdgeInsets.only(
                      top: 40, left: 20, right: 20, bottom: 60),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      buildMainHeading('Prescription Sheet'),
                      pw.SizedBox(height: 10),

                      pw.Text(
                        "This sheet lists all prescribed medications for the patient, including the medicine name (commercial or generic), strength, dosage instructions, and prescribing doctor. "
                        "The Medication Status indicates whether the medicine is still currently being taken by the patient (Valid) or has been discontinued (Invalid).",
                        style: pw.TextStyle(font: notoFont, fontSize: 12),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 20),

                      // Table Header
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey400),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2),
                          1: const pw.FlexColumnWidth(1.5),
                          2: const pw.FlexColumnWidth(1.5),
                          3: const pw.FlexColumnWidth(2),
                          4: const pw.FlexColumnWidth(2),
                        },
                        children: [
                          pw.TableRow(
                            decoration:
                                pw.BoxDecoration(color: PdfColors.grey300),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Medicine Name",
                                    style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Strength", style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Dosage", style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Prescribed By",
                                    style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Medication Status",
                                    style: headerStyle),
                              ),
                            ],
                          ),

                          // Data rows
                          ...prescriptionData.map<pw.TableRow>((drug) {
                            final medicineName = (drug['Commercial_name']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false)
                                ? drug['Commercial_name']
                                : (drug['Generic_name'] ?? 'N/A');

                            return pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child:
                                      pw.Text(medicineName, style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(drug['Strength'] ?? 'N/A',
                                      style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(drug['Dosage'] ?? 'N/A',
                                      style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    drug['Doctor_Name'] != null
                                        ? 'Dr. ${drug['Doctor_Name']}'
                                        : 'N/A',
                                    style: cellStyle,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                      drug['Medication_Status'] ?? 'N/A',
                                      style: cellStyle),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer
                pw.Align(
                  alignment: pw.Alignment.bottomCenter,
                  child: footer,
                ),
              ],
            );
          },
        ),
      );
    }

//drug sheet
    if ((drugSheetData['data'] ?? []).isNotEmpty)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final List<dynamic> data = drugSheetData['data'] ?? [];

            final headerStyle = pw.TextStyle(
              font: notoFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            );

            final cellStyle = pw.TextStyle(
              font: notoFont,
              fontSize: 11,
            );

            return pw.Stack(
              children: [
                // Page number at the top
                pw.Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: buildPageNumber(context, font: notoFont),
                ),

                // Content
                pw.Padding(
                  padding: const pw.EdgeInsets.only(
                      top: 40, left: 20, right: 20, bottom: 60),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      buildMainHeading('Drug Sheet'),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        "This sheet tracks all the medicines administered to the patient during their hospital stay. "
                        "Each entry includes the medicine name, its strength, dosage, the date and time it was given, and the shift during which it was administered.",
                        style: pw.TextStyle(font: notoFont, fontSize: 12),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 20),

                      // Table
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey400),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2),
                          1: const pw.FlexColumnWidth(1.5),
                          2: const pw.FlexColumnWidth(1.5),
                          3: const pw.FlexColumnWidth(2),
                          4: const pw.FlexColumnWidth(2),
                          5: const pw.FlexColumnWidth(1.5),
                        },
                        children: [
                          // Table Header
                          pw.TableRow(
                            decoration:
                                pw.BoxDecoration(color: PdfColors.grey300),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Medicine Name",
                                    style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Strength", style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Dosage", style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Date", style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Time", style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text("Shift", style: headerStyle),
                              ),
                            ],
                          ),

                          // Table Rows
                          ...data.map<pw.TableRow>((drug) {
                            final medicineName = (drug['Commercial_name']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false)
                                ? drug['Commercial_name']
                                : (drug['Generic_name'] ?? 'N/A');

                            final date = (drug['Date'] != null &&
                                    DateTime.tryParse(drug['Date']) != null)
                                ? DateFormat('yyyy-MM-dd')
                                    .format(DateTime.parse(drug['Date']))
                                : 'N/A';

                            final time = (drug['Time'] != null &&
                                    DateTime.tryParse(drug['Time']) != null)
                                ? DateFormat('hh:mm a')
                                    .format(DateTime.parse(drug['Time']))
                                : 'N/A';

                            return pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child:
                                      pw.Text(medicineName, style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(drug['Strength'] ?? 'N/A',
                                      style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(drug['Dosage'] ?? 'N/A',
                                      style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(date, style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(time, style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(drug['Shift'] ?? 'N/A',
                                      style: cellStyle),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer
                pw.Align(
                  alignment: pw.Alignment.bottomCenter,
                  child: footer,
                ),
              ],
            );
          },
        ),
      );
    final data = progressReportData['data'] ?? [];

    if (data.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final headerStyle = pw.TextStyle(
                font: notoFont, fontSize: 12, fontWeight: pw.FontWeight.bold);
            final bodyStyle = pw.TextStyle(font: notoFont, fontSize: 11);

            String startDate = formatDate(data.first['Progress_Date']);
            String endDate = formatDate(data.last['Progress_Date']);
            String firstName = getFirstName(patientName);

            return pw.DefaultTextStyle(
              style: pw.TextStyle(font: notoFont),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Align(
                    alignment: pw.Alignment.topRight,
                    child: buildPageNumber(context, font: notoFont),
                  ),
                  buildMainHeading('Progress Sheet'),
                  pw.Text('Name: $patientName',
                      style: pw.TextStyle(
                          font: notoFont,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Patient ID: $patientID',
                      style: pw.TextStyle(font: notoFont, fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'This report provides an overview of $firstName\'s progress based on the daily notes provided by the attending doctor. '
                    '*Progress information covers the period from $startDate to $endDate.',
                    style: pw.TextStyle(font: notoFont, fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: pw.FixedColumnWidth(30),
                      1: pw.FixedColumnWidth(80),
                      2: pw.FlexColumnWidth(),
                      3: pw.FixedColumnWidth(100),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text('S.N', style: headerStyle),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text('Date', style: headerStyle),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text('Notes', style: headerStyle),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text('Reported By', style: headerStyle),
                            ),
                          ),
                        ],
                      ),
                      ...List.generate(data.length, (index) {
                        final report = data[index];
                        final formattedDate =
                            formatDate(report['Progress_Date'] ?? 'Unknown');
                        final doctorName = report['Doctor'] ?? '-';
                        final reportedBy =
                            doctorName.toLowerCase().startsWith('dr.')
                                ? doctorName
                                : 'Dr. $doctorName';

                        return pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: pw.EdgeInsets.all(4),
                                child:
                                    pw.Text('${index + 1}', style: bodyStyle)),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(4),
                                child:
                                    pw.Text(formattedDate, style: bodyStyle)),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(report['Notes'] ?? '-',
                                    style: bodyStyle)),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(reportedBy, style: bodyStyle)),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      print("No progress report data found. Page not added.");
    }

    final List<dynamic> rawConsultations = consultationSheetData['data'] ?? [];

// Check if any consultation has a valid ConsultationID (not null and not empty string)
    final bool hasValidConsultation = rawConsultations.any(
      (item) =>
          item['ConsultationID'] != null &&
          '${item['ConsultationID']}'.trim().isNotEmpty,
    );

    print('Has valid consultation data: $hasValidConsultation');

    if (hasValidConsultation) {
      // Use the original data to build, no need to filter now
      final consultationBody = _buildConsultationBody(
        consultationSheetData,
        font: notoFont,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildPageNumber(context, font: notoFont),
              pw.SizedBox(height: 6),
              buildMainHeading('Consultation Sheet'),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.center,
            child: footer,
          ),
          build: (context) => consultationBody,
        ),
      );
    } else {
      print('No valid ConsultationID found. Skipping Consultation Sheet page.');
    }

    //Discharge Sheet

    pdf.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  buildPageNumber(context, font: notoFont),
                  buildMainHeading('Discharge Sheet'),
                  pw.SizedBox(height: 10),
                ],
              ),
          footer: (context) => pw.Align(
                alignment: pw.Alignment.center,
                child: footer,
              ),
          build: (context) => [
                // Directly writing the section here

                // Main Heading
                pw.Center(
                  child: pw.Text(
                    'DISCHARGE SUMMARY',
                    style: pw.TextStyle(
                      font: notoFont,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                // Patient Information
                pw.Text('Patient Information',
                    style: sectionHeaderStyle.copyWith(font: notoFont)),
                pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                pw.SizedBox(height: 8),

// Row 1: Admission No, Patient ID, Ward / Bed
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Align(
                            alignment: pw.Alignment.center,
                            child: pw.Text('Adm No: $admissionNo',
                                style: pw.TextStyle(font: notoFont)),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Align(
                            alignment: pw.Alignment.center,
                            child: pw.Text('Patient ID: $patientID',
                                style: pw.TextStyle(font: notoFont)),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Align(
                            alignment: pw.Alignment.center,
                            child: pw.Text('Ward No: $wardNo',
                                style: pw.TextStyle(font: notoFont)),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Align(
                            alignment: pw.Alignment.center,
                            child: pw.Text('Bed No: $bedNo',
                                style: pw.TextStyle(font: notoFont)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

// Row 2: Name, Age / Gender
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Name: $contactNumber',
                          style: pw.TextStyle(font: notoFont)),
                    ),
                    pw.Expanded(
                      child: pw.Text('Age/Gender: $age/$gender',
                          style: pw.TextStyle(font: notoFont)),
                    ),
                  ],
                ),

                pw.SizedBox(height: 6),

// Row 3: Address (can be full width if long)
                pw.Container(
                  width: double.infinity, // Take up full width
                  child: pw.Text('Address: $address',
                      style: pw.TextStyle(font: notoFont)),
                ),

                pw.SizedBox(height: 6),

// Row 4: Mobile, CNIC
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Mobile No: $contactNumber',
                          style: pw.TextStyle(font: notoFont)),
                    ),
                    pw.Expanded(
                      child: pw.Text('CNIC No: $CNIC',
                          style: pw.TextStyle(font: notoFont)),
                    ),
                  ],
                ),

                pw.SizedBox(height: 6),

// Row 5: Admission / Discharge Dates
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                          'Date of Admission: ${formatDate(admissionDate)}',
                          style: pw.TextStyle(font: notoFont)),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                          'Date of Discharge: ${formatDate(dischargeDate)}',
                          style: pw.TextStyle(font: notoFont)),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                pw.SizedBox(height: 10),
                pw.Text(
                  'History:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: notoFont,
                      fontSize: 16),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.grey100, // Optional: subtle background
                  ),
                  child: pw.Text(
                    receivingNote ?? 'Not available',
                    style: pw.TextStyle(font: notoFont),
                  ),
                ),
                pw.SizedBox(height: 8),

                //Investigation Section
                pw.Text('Investigations',
                    style: sectionHeaderStyle.copyWith(font: notoFont)),

                pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                pw.SizedBox(height: 8),

// 🔹 Subsection 1: Report Findings & Diagnosis
                pw.Text('1. Report Findings:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: notoFont,
                        fontSize: 14)),
                pw.SizedBox(height: 4),

                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ', style: pw.TextStyle(font: notoFont)),
                    pw.Expanded(
                      child: pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: notoFont),
                          children: [
                            pw.TextSpan(text: 'CT Scan: '), // <-- No bold
                            pw.TextSpan(text: CTScan),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ', style: pw.TextStyle(font: notoFont)),
                    pw.Expanded(
                      child: pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: notoFont),
                          children: [
                            pw.TextSpan(text: 'MRI: '), // <-- No bold
                            pw.TextSpan(text: MRI),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ', style: pw.TextStyle(font: notoFont)),
                    pw.Expanded(
                      child: pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: notoFont),
                          children: [
                            pw.TextSpan(text: 'Others: '), // <-- No bold
                            pw.TextSpan(text: otherFindings),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 6),
                pw.Text('Diagnosis Based on Reports:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, font: notoFont)),

                pw.SizedBox(height: 6), // Add spacing between heading and box

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(
                      8), // You can slightly increase padding too
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey500),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(associateDiagnosis ?? 'Not available',
                      style: pw.TextStyle(font: notoFont)),
                ),

                pw.SizedBox(height: 10),

                if (surgeryDetails != null &&
                    surgeryDetails != 'Not applicable') ...[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '2. Surgery (if any):',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      font: notoFont,
                    ),
                  ),
                  pw.SizedBox(height: 6),

// Bullet 1
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('•  ', style: pw.TextStyle(font: notoFont)),
                      pw.Expanded(
                        child: pw.Text('Surgery Performed: $surgeryDetails',
                            style: pw.TextStyle(font: notoFont)),
                      ),
                    ],
                  ),

// Bullet 2
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('•  ', style: pw.TextStyle(font: notoFont)),
                      pw.Expanded(
                        child: pw.Text('Operative Findings: $operativeFindings',
                            style: pw.TextStyle(font: notoFont)),
                      ),
                    ],
                  ),

// Bullet 3
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('•  ', style: pw.TextStyle(font: notoFont)),
                      pw.Expanded(
                        child: pw.Text('Biopsy Report: $biopsyReport',
                            style: pw.TextStyle(font: notoFont)),
                      ),
                    ],
                  ),
                ],
                // New Section: Post-Discharge Care Instructions
                pw.SizedBox(height: 20),

                //Investigation Section
                pw.Text('Discharge Treatment',
                    style: sectionHeaderStyle.copyWith(font: notoFont)),

                pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                pw.SizedBox(height: 6),
                // 1. Condition at the Time of Discharge
                pw.Text(
                  'Condition at the Time of Discharge',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    font: notoFont,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(
                      8), // You can slightly increase padding too
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey500),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(conditionAtDischarge,
                      style: pw.TextStyle(font: notoFont)),
                ),
                pw.SizedBox(height: 15),

// 2. Discharge Treatment
                pw.Text(
                  'Discharge Treatment',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    font: notoFont,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  dischargeTreatment,
                  style: pw.TextStyle(
                      font: notoFont, lineSpacing: 5, fontSize: 14),
                ),
                pw.SizedBox(height: 15),

// 3. Follow-up
                pw.Text(
                  'Follow-up',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    font: notoFont,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  followUp,
                  style: pw.TextStyle(
                      font: notoFont, lineSpacing: 5, fontSize: 14),
                ),
                pw.SizedBox(height: 15),

// 4. Instructions
                pw.Text(
                  'Instructions',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    font: notoFont,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  instructions,
                  style: pw.TextStyle(
                      font: notoFont, lineSpacing: 5, fontSize: 14),
                ),
                pw.SizedBox(height: 25),

// Final Row: Dr Name, Signature, Discharge Date & Time
                // Doctor Name and Signature Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Discharged By: Dr. $doctorName',
                      style: pw.TextStyle(font: notoFont),
                    ),
                    pw.Text(
                      'Signature: __________________',
                      style: pw.TextStyle(font: notoFont),
                    ),
                  ],
                ),

                pw.SizedBox(height: 6),

// Discharge Date and Time Row
                pw.Text(
                  '${formatDate(dischargeDate)} | ${formatTimeFromString(dischargeTime)}',
                  style: pw.TextStyle(font: notoFont),
                ),
              ]),
    );


    // Save PDF
    // await savePdfToFile(pdf, patientID,admissionNo);
    final fileName = 'HF_${admissionNo}_$patientID.pdf';
    final pdfBytes = await pdf.save(); // Get PDF as Uint8List

    final driveService = GoogleDriveService();
    bool uploadSuccess =
        await driveService.uploadPdfsToDrive(pdfBytes, fileName);
    if (uploadSuccess) {
      final statusUpdated = await UsersServices.updateUploadToCloudStatus(
        admissionNo: admissionNo,
        uploadedToCloud: true,
      );

      if (statusUpdated) {
        print("Upload status updated in DB.");
      } else {
        print("Failed to update upload status in DB.");
      }
    }

    return uploadSuccess;
  }

  // Optionally, add helper methods like this if needed
  String _getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }
}
