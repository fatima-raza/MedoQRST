//File sheet
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dischargeWidget.dart';
import '../../utils/date_time_utils.dart';

void showSheetPopup(
    BuildContext context, String sheetName, Map<String, dynamic> data) {
  print('Sheet Name: $sheetName');

// Check if data is null and assign an empty map if necessary
  print('Data Received: ${data?.toString() ?? "No data available"}');

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (context) {
      Widget sheetContent;

      switch (sheetName) {
        case 'Registration Sheet':
          sheetContent = _buildRegistrationSheet(data);
          break;

        case 'Receiving Notes':
          sheetContent = _buildReceivingNotesSheet(data);
          break;

        case 'Progress Report':
          sheetContent = _buildProgressSheet(data);
          break;

        case 'Consultation Sheet':
          // Ensure that 'data' contains a key 'data' which holds the list of consultations
          List<Map<String, dynamic>> consultationList =
              List<Map<String, dynamic>>.from(data['data'] ?? []);

          sheetContent = buildConsultationSheet(consultationList);

          break;

        case 'Discharge Sheet':
          sheetContent = _buildDischargeSheet(data);
          break;

        case 'Prescription Sheet':
          sheetContent = _buildPrescriptionSheet(data);
          break;

        case 'Drug Sheet':
          sheetContent = _buildDrugSheet(data);
          break;

        default:
          sheetContent = _buildDefaultSheet(data);
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: 1000, // Set a fixed width
                  height: 500, // Set a fixed height
                  child: SingleChildScrollView(
                    child: sheetContent,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String safeString(dynamic value) {
  return (value == null || value.toString().trim().isEmpty)
      ? '--'
      : value.toString();
}

// Helper function to format the date
String formatDate(String? dateStr) {
  try {
    if (dateStr == null) return 'Unknown';
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('d MMMM, yyyy').format(date); // Format the date as needed
  } catch (_) {
    return 'Unknown';
  }
}

Widget _buildRegistrationSheet(Map<String, dynamic> data) {
  final registration = data['registration'];
  final nextOfKin = data['nextofkin']?['data']?[0];
  final formatted = getFormattedDateTime(data['registration']['Admission_date'],
      data['registration']['Admission_time']);

  final formattedDate = formatted['date']!;
  final formattedTime = formatted['time']!;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: Text(
          'Registration Sheet',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.blue[900],
          ),
        ),
      ),
      SizedBox(height: 10),
      Divider(thickness: 1.5),
      SizedBox(height: 20),

      // Patient Information Section
      _buildSectionHeader("Patient Information"),
      _buildFormRow("Name", data['user']['Name']),
      _buildFormRow("ID", data['user']['UserID']),
      _buildFormRow("Age", data['user']['Age']),
      _buildFormRow("Gender", data['user']['Gender']),
      _buildFormRow("CNIC", data['user']['CNIC']),
      _buildFormRow("Phone No",
          "${data['user']['Contact_number']} | ${data['user']['Alternate_contact_number']}"),
      _buildFormRow("Address", data['user']['Address']),

      SizedBox(height: 15),

      // Registration Information Section
      _buildSectionHeader("Admission Information"),
      _buildFormRow("Admission No", data['registration']['Admission_no']),
      _buildFormRow(
          "Mode of Admission", data['registration']['Mode_of_admission']),
      _buildFormRow("Admitted Date & Time", "$formattedDate | $formattedTime"),
      _buildFormRow("Ward No/ Bed No",
          "${data['registration']['Ward_no']} / ${data['registration']['Bed_no']}"),

      SizedBox(height: 15),

      // Contact Information Section
      _buildSectionHeader("Emergency Contact"),

      _buildFormRow("Next Of Kin To Inform", nextOfKin?['Name']),
      _buildFormRow("Relation with Patient", nextOfKin?['Relationship']),
      _buildFormRow("Emergency Contact", nextOfKin?['Contact_no']),

      // fallback or emergency contact field

      SizedBox(height: 20),
    ],
  );
}

Widget _buildReceivingNotesSheet(Map<String, dynamic> data) {
  final registration = data['registration'];
  final notes = data['vitals'] ?? {};
  final notesList = notes['data'];
  final firstNote =
      (notesList != null && notesList.isNotEmpty) ? notesList[0] : {};

  final formatted = getFormattedDateTime(data['registration']['Admission_date'],
      data['registration']['Admission_time']);

  final formattedDate = formatted['date']!;
  final formattedTime = formatted['time']!;

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Center(
      child: Text(
        'Receiving Notes',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.blue[900],
        ),
      ),
    ),
    Divider(thickness: 1.5),

    SizedBox(height: 10),

    SizedBox(height: 20),
// Admission Details
    _buildSectionHeader("Admitted Condition"),
    _buildFormRow("Receiving Note", registration['Receiving_note']),

// Diagnostic Details
    _buildSectionHeader("Diagnostic Details"),
    _buildFormRow("Primary Diagnosis", registration['Primary_diagnosis']),
    _buildFormRow("Associate Diagnosis", registration['Associate_diagnosis']),

    SizedBox(height: 15),

// Patient Vitals Section

    _buildSectionHeader("Patient Vitals"),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        columnWidths: {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            children: [
              _buildTableCell("Blood Pressure"),
              _buildTableCell(
                firstNote['Blood_pressure'] == null
                    ? '--'
                    : "${safeString(firstNote['Blood_pressure'])} mmHg",
              ),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell("Pulse"),
              _buildTableCell(
                firstNote['Pulse_rate'] == null
                    ? '--'
                    : "${safeString(firstNote['Pulse_rate'])} bpm",
              ),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell("Temperature"),
              _buildTableCell(
                firstNote['Temperature'] == null
                    ? '--'
                    : "${safeString(firstNote['Temperature'])} °F",
              ),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell("Respiratory Rate"),
              _buildTableCell(
                firstNote['Respiration_rate'] == null
                    ? '--'
                    : "${safeString(firstNote['Respiration_rate'])} breaths/min",
              ),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell("SPO2"),
              _buildTableCell(
                firstNote['Oxygen_saturation'] == null
                    ? '--'
                    : "${safeString(firstNote['Oxygen_saturation'])} %",
              ),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell("Blood Sugar"),
              _buildTableCell(
                firstNote['Random_blood_sugar'] == null
                    ? '--'
                    : "${safeString(firstNote['Random_blood_sugar'])} mg/dL",
              ),
            ],
          ),
        ],
      ),
    ),
    SizedBox(height: 20),

    Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, right: 8.0),
        child: Text(
          'Admitted on: $formattedDate | $formattedTime',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[800],
            letterSpacing: 0.5,
          ),
        ),
      ),
    )
  ]);
}

Widget _buildPrescriptionSheet(Map<String, dynamic> drugResponse) {
  List<dynamic> drugData = drugResponse['data'] ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Always show this heading
      Center(
        child: Text(
          'Prescription Sheet',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.blue[900],
          ),
        ),
      ),
      SizedBox(height: 10),
      Divider(thickness: 2),
      SizedBox(height: 20),

      // If no prescription data found
      if (drugData.isEmpty)
        _buildNoDataMessage('No Prescription data found')
      else ...[
        // Description shown only if data exists
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            "This sheet lists all prescribed medications for the patient, including the medicine name (commercial or generic), strength, dosage instructions, and prescribing doctor. "
            "The Medication Status indicates whether the medicine is still currently being taken by the patient (Valid) or has been discontinued (Invalid).",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        SizedBox(height: 20),

        // Table
        Table(
          border: TableBorder.all(color: Colors.black26),
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey[50]),
              children: [
                _buildColoredTableCell("Medicine Name"),
                _buildColoredTableCell("Strength"),
                _buildColoredTableCell("Dosage"),
                _buildColoredTableCell("Prescribed By"),
                _buildColoredTableCell("Medication Status"),
              ],
            ),
            // Data rows
            for (var drug in drugData)
              TableRow(children: [
                _buildTableCell(
                  (drug['Commercial_name']?.isNotEmpty ?? false)
                      ? drug['Commercial_name']
                      : (drug['Generic_name'] ?? 'N/A'),
                ),
                _buildTableCell(drug['Strength'] ?? 'N/A'),
                _buildTableCell(drug['Dosage'] ?? 'N/A'),
                _buildTableCell(
                  drug['Doctor_Name'] != null
                      ? 'Dr. ${drug['Doctor_Name']}'
                      : 'N/A',
                ),
                _buildTableCell(drug['Medication_Status'] ?? 'N/A'),
              ]),
          ],
        ),
        SizedBox(height: 20),
      ],
    ],
  );
}

Widget _buildDrugSheet(Map<String, dynamic> drugResponse) {
  List<dynamic> drugData = drugResponse['data'] ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: Text(
          'Drug Sheet',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.blue[900],
          ),
        ),
      ),
      SizedBox(height: 10),
      Divider(thickness: 2),
      SizedBox(height: 20),

      // Handle empty data
      if (drugData.isEmpty)
        _buildNoDataMessage('No Drug Sheet data found')
      else ...[
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            "This sheet tracks all the medicines administered to the patient during their hospital stay. "
            "Each entry includes the medicine name, its strength, dosage, the date and time it was given, and the shift during which it was administered.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        SizedBox(height: 20),

        // Table
        Table(
          border: TableBorder.all(color: Colors.black26),
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(1.8),
            5: FlexColumnWidth(1.5),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey[50]),
              children: [
                _buildColoredTableCell("Medicine Name"),
                _buildColoredTableCell("Strength"),
                _buildColoredTableCell("Dosage"),
                _buildColoredTableCell("Date"),
                _buildColoredTableCell("Time"),
                _buildColoredTableCell("Shift"),
              ],
            ),
            // Rows
            for (var drug in drugData)
              TableRow(children: [
                _buildTableCell(
                  (drug['Commercial_name']?.isNotEmpty ?? false)
                      ? drug['Commercial_name']
                      : (drug['Generic_name'] ?? 'N/A'),
                ),
                _buildTableCell(drug['Strength'] ?? 'N/A'),
                _buildTableCell(drug['Dosage'] ?? 'N/A'),
                _buildTableCell(
                  (drug['Date'] != null &&
                          DateTime.tryParse(drug['Date']) != null)
                      ? formatDateCompact(DateTime.parse(drug['Date']))
                      : 'N/A',
                ),
                _buildTableCell(
                  (drug['Time'] != null &&
                          DateTime.tryParse(drug['Time']) != null)
                      ? formatTime(DateTime.parse(drug['Time']))
                      : 'N/A',
                ),
                _buildTableCell(drug['Shift'] ?? 'N/A'),
              ]),
          ],
        ),
        SizedBox(height: 20),
      ],
    ],
  );
}

Widget _buildProgressSheet(Map<String, dynamic> data) {
  // Extracting the patient name and patient ID
  final String patientName = data['Name'] ?? 'Unknown';
  final String patientId = data['UserID']?.toString() ?? 'N/A';
  final String Admission_no = data['Admission_no']?.toString() ?? 'N/A';

  // Destructure the progress entries from the data map
  List<dynamic> progressList = [];
  if (data.containsKey('data')) {
    progressList = List.from(data['data'] ?? []);
  }

  // Extract Admission No (if available from first progress entry)
  String admissionNo = 'N/A';
  if (progressList.isNotEmpty &&
      progressList.first.containsKey('Admission_no')) {
    admissionNo = progressList.first['Admission_no']?.toString() ?? 'N/A';
  }

  if (data.containsKey('data')) {
    progressList = List.from(data['data'] ?? []);
  }

  String firstName = patientName.split(" ").first;
  // Fetching start and end dates from the progress entries
  String startDate = 'Unknown';
  String endDate = 'Unknown';

  if (progressList.isNotEmpty) {
    // Assuming 'Progress_Date' is the key where the date is stored in each entry
    startDate = formatDate(progressList.first['Progress_Date']);
    endDate = formatDate(progressList.last['Progress_Date']);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Heading
      Center(
        child: Text(
          'Progress Report',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.blue[900],
          ),
        ),
      ),
      Divider(thickness: 1.5),
      SizedBox(height: 10),

      // Top header info (always visible)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey[100]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.blueGrey[100]!),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Patient Name: $patientName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.blueGrey[100]!),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Admission No: $Admission_no',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Patient ID: $patientId',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      SizedBox(height: 12),

      // Description Text (only when there is progress data)
      if (progressList.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            "This report provides an overview of $firstName's progress based on the daily notes provided by the attending doctor. *Progress information covers the period from $startDate to $endDate",
            style: TextStyle(fontSize: 15),
          ),
        ),
      SizedBox(height: 20),

      // Table Header (only when there is progress data)
      if (progressList.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            color: Colors.blueGrey[100],
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text("S.No",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Date",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 4,
                  child: Text("Notes",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text("Reported By",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),

      // Table Data Rows (only when there is progress data)
      if (progressList.isEmpty)
        // Display message if no progress data is available
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text("No progress entries available."),
          ),
        )
      else
        // Display the progress entries table if data is available
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: progressList.length,
          itemBuilder: (context, index) {
            final entry = progressList[index];
            final rawDate = entry['Progress_Date'];
            final date =
                formatDateCompact(DateTime.parse(rawDate)); // ✅ dd-MM-yyyy
            final doctor = entry['Doctor'] ?? '';
            final notes = entry['Notes'] ?? '';

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text("${index + 1}",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(date,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(notes,
                        style: TextStyle(fontWeight: FontWeight.normal)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text("Dr. $doctor",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          },
        ),

      SizedBox(height: 20),
    ],
  );
}

Widget buildConsultationSheet(List<Map<String, dynamic>> consultationData) {
  final validConsultations = consultationData
      .where((consultation) => consultation['ConsultationID'] != null)
      .toList();

  final patientID = consultationData.isNotEmpty
      ? consultationData.first['PatientID'] ?? 'Unknown'
      : 'Unknown';

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Consultation Sheet',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.blue[900],
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(thickness: 2),
          SizedBox(height: 10),
          if (validConsultations.isEmpty)
            _buildNoDataMessage('No Consultation data found')
          else ...[
            Text(
              validConsultations.length == 1
                  ? 'Following is the consultation record. Total consultations: 1'
                  : 'Following are the consultation records. Total consultations: ${validConsultations.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ...validConsultations.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> consultation = entry.value;

              final consultationID = consultation['ConsultationID'] ?? 'No ID';
              final admissionNo =
                  consultation['Admission_no'] ?? 'No Admission No';
              // final rawDate = consultation['Date'] ?? '';
              final requestingDepartment =
                  consultation['Requesting_Department'] ?? 'No Department';
              final consultingDepartment =
                  consultation['Consulting_Department'] ?? 'No Department';
              final requestingDoctor =
                  consultation['Requesting_Doctor'] ?? 'No Doctor';
              final consultationType =
                  consultation['Type_of_Comments'] ?? 'Unknown';
              final reason = consultation['Reason'] ?? 'No Reason Provided';
              final dateStr = consultation['Date'] ?? '';
              final timeStr = consultation['Time'] ?? '';

              String formattedDate = 'Invalid Date';
              String formattedTime = 'Invalid Time';

              if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
                try {
                  final formatted = getFormattedDateTime(dateStr, timeStr);
                  formattedDate = formatted['date']!;
                  formattedTime = formatted['time']!;
                } catch (e) {
                  // Defaults remain
                }
              }

              return Container(
                width: 900,
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.blueGrey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Consultation #${index + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildSectionHeader('Consultation Details'),
                    SizedBox(height: 12),
                    _buildTwoColumnRow('Consultation ID', consultationID,
                        'Admission No', admissionNo),
                    SizedBox(height: 12),
                    _buildTwoColumnRow(
                        'Date', formattedDate, 'Time', formattedTime),
                    SizedBox(height: 20),
                    _buildSectionHeader('Request Details'),
                    SizedBox(height: 12),
                    _buildTwoColumnRow(
                        'Requesting Department',
                        requestingDepartment,
                        'Consulting Department',
                        consultingDepartment),
                    SizedBox(height: 12),
                    _buildTwoColumnRow('Requesting Doctor', requestingDoctor,
                        'Consultation Type', consultationType),
                    SizedBox(height: 20),
                    _buildSectionHeader('Consultation Reason'),
                    SizedBox(height: 12),
                    _buildSingleRow(reason),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    ),
  );
}

Widget _buildTwoColumnRow(
    String label1, String value1, String label2, String value2) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: _buildLabeledText(label1, value1)),
      SizedBox(width: 20),
      Expanded(
          child: label2.isNotEmpty
              ? _buildLabeledText(label2, value2)
              : Container()),
    ],
  );
}

Widget _buildLabeledText(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(fontSize: 15, color: Colors.black),
      ),
    ],
  );
}

Widget _buildSingleRow(String value) {
  return Text(
    value,
    style: TextStyle(fontSize: 15, color: Colors.black),
  );
}

Widget _buildDischargeSheet(Map<String, dynamic> data) {
  return DischargeWidget(
      data: data); // DischargeWidget defined in a separate file
}

Widget buildReceivingNotes(List<Map<String, dynamic>> receivingNotesData) {
  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receiving Notes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          ...receivingNotesData.map((note) {
            final admissionNo = note['Admission_no'] ?? 'No Admission No';
            final recordedAt = note['Recorded_at'] ?? 'No recording date';
            final bloodPressure = note['Blood_pressure'] ?? 'No BP';
            final respirationRate =
                note['Respiration_rate'] ?? 'No respiration rate';
            final pulseRate = note['Pulse_rate'] ?? 'No pulse rate';
            final oxygenSaturation =
                note['Oxygen_saturation'] ?? 'No oxygen saturation';
            final temperature = note['Temperature'] ?? 'No temperature';
            final randomBloodSugar =
                note['Random_blood_sugar'] ?? 'No blood sugar';

            return Container(
              margin: EdgeInsets.symmetric(vertical: 6),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admission No: $admissionNo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Recorded At: $recordedAt'),
                  SizedBox(height: 4),
                  Text('Blood Pressure: $bloodPressure'),
                  SizedBox(height: 4),
                  Text('Respiration Rate: $respirationRate'),
                  SizedBox(height: 4),
                  Text('Pulse Rate: $pulseRate'),
                  SizedBox(height: 4),
                  Text('Oxygen Saturation: $oxygenSaturation'),
                  SizedBox(height: 4),
                  Text('Temperature: $temperature'),
                  SizedBox(height: 4),
                  Text('Random Blood Sugar: $randomBloodSugar'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}

// Helper Methods to build table cells (assuming you have these already)
Widget _buildColoredTableCell(String text) {
  return Padding(
    padding: EdgeInsets.all(8.0),
    child: Text(
      text,
      style: TextStyle(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    ),
  );
}

// Function to format the Date (parsing string to DateTime)
String _formatDate(String date) {
  try {
    // Parse the string into DateTime
    DateTime parsedDate = DateTime.parse(
        date); // Assuming it's in a standard format like 'yyyy-MM-dd'

    // Format the DateTime object to the desired format
    return DateFormat('dd-MM-yyyy').format(parsedDate);
  } catch (e) {
    print("Error formatting date: $e");
    return 'Invalid Date';
  }
}

// Function to format the Time (parsing string to DateTime)
String _formatTime(String time) {
  try {
    // Extract the time portion from the ISO string and parse it as a DateTime
    // We assume the time is in the format `1970-01-01T08:35:22.353Z`
    final timeOnly = time.split('T')[1];
    DateTime parsedTime = DateTime.parse(
        '1970-01-01 $timeOnly'); // Adding date part for valid DateTime parsing

    // Format the DateTime object to the desired time format
    return DateFormat('hh:mm a').format(parsedTime);
  } catch (e) {
    print("Error formatting time: $e");
    return 'Invalid Time';
  }
}

Widget _buildTableCell(String content) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      content,
      style: TextStyle(fontSize: 16),
      textAlign: TextAlign.center,
    ),
  );
}

Widget _buildFormRow(String title, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            "$title:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.blueGrey[900],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDefaultSheet(Map<String, dynamic> data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: Text(
          "Sheet Details",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.black87,
          ),
        ),
      ),
      SizedBox(height: 10),
      Divider(thickness: 1.5),
      SizedBox(height: 10),
      if (data.isEmpty)
        Center(
          child: Text(
            "No data available for this sheet.",
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        )
      else
        ...data.entries.map((entry) {
          return _buildFormRow(entry.key, entry.value);
        }).toList(),
    ],
  );
}

Widget _buildSectionHeader(String title) {
  return Container(
      width: double.infinity,
      color: Colors.blueGrey[100],
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ));
}

Widget _buildNoDataMessage(String message) {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 18,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
          fontWeight: FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
