import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/users_services.dart'; // adjust the path if needed
import '../utils/date_time_utils.dart';

class DischargeWidget extends StatefulWidget {
  // final String admissionID;
  final Map<String, dynamic> data; // Accepting data
  // final void Function(bool) onSummaryStatusChanged;

  const DischargeWidget({
    Key? key,
    // required this.admissionID,
    required this.data, // Using the data parameter
    // required this.onSummaryStatusChanged,
  }) : super(key: key);

  @override
  State<DischargeWidget> createState() => _DischargeWidgetState();
}

class _DischargeWidgetState extends State<DischargeWidget> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Destructure the data parameter
    final registration = widget.data['registration'];
    final discharge = widget.data['discharge'];
    final userData = widget.data['userData'];

    // Check if discharge data exists
    if (discharge == null ||
        discharge['data'] == null ||
        (discharge['data'] as List).isEmpty) {
      return _buildDischargeSheetWithoutDischargeData(registration, userData);
    }

    return _buildDischargeSheet(
      registration,
      discharge,
      userData,
    );
  }

  Widget _buildDischargeSheetWithoutDischargeData(
      Map<String, dynamic> registration, Map<String, dynamic> userData) {
    final admissionNo = registration['Admission_no'] ?? 'N/A';
    final patientId = userData['UserID'] ?? 'N/A';
    final wardNo = registration['Ward_no']?.toString() ?? 'N/A';
    final bedNo = registration['Bed_no']?.toString() ?? 'N/A';
    final doctor = registration['doctor'] ?? 'N/A';

    DateTime? admissionDateTime;
    String formattedAdmissionDate = 'N/A';

    final admissionDateRaw = registration['Admission_date'];

    if (admissionDateRaw != null) {
      try {
        admissionDateTime = DateTime.parse(admissionDateRaw);
        formattedAdmissionDate = formatDate(
            admissionDateTime); // Util function from date_time_utils.dart
      } catch (e) {
        print('Invalid admission date format: $e');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Patient Information - No Discharge Entries Found!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader("PATIENT INFORMATION"),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.black26),
            children: [
              TableRow(children: [
                _buildTableCell("Admission No"),
                _buildTableCell("Patient ID"),
                _buildTableCell("Ward No"),
                _buildTableCell("Bed No"),
              ]),
              TableRow(children: [
                _buildTableCell(admissionNo),
                _buildTableCell(patientId),
                _buildTableCell(wardNo),
                _buildTableCell(bedNo),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          _buildFormRow("Name", userData['Name']),
          _buildFormRow(
              "Age / Gender", "${userData['Age']} / ${userData['Gender']}"),
          _buildFormRow("Address", userData['Address']),
          _buildFormRow("Mobile No", userData['Contact_number']),
          _buildFormRow("CNIC", userData['CNIC']),
          _buildFormRow("Date of Admission", formattedAdmissionDate),
          _buildFormRow("Admitted under the care of", 'Dr. $doctor'),
          const SizedBox(height: 20),
          _sectionHeader("DISCHARGE SUMMARY"),
          const SizedBox(height: 10),
          Text(
            'No Discharge Details found ',
            style: TextStyle(fontSize: 16, color: Colors.blue[900]),
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeSheet(
    Map<String, dynamic> registration,
    Map<String, dynamic> discharge,
    Map<String, dynamic> userData,
  ) {
    final dischargeList = discharge['data'];
    final firstDischarge = (dischargeList != null && dischargeList.isNotEmpty)
        ? dischargeList[0]
        : {};

    final admissionNo = registration['Admission_no'] ?? 'N/A';
    final patientId = userData['UserID'] ?? 'N/A';
    final wardNo = registration['Ward_no']?.toString() ?? 'N/A';
    final bedNo = registration['Bed_no']?.toString() ?? 'N/A';
    final doctor = registration['doctor'] ?? 'N/A';

    // DateTime? dischargeDateTime;
    // String formattedDischargeDate = 'N/A';
    // String formattedDischargeTime = 'N/A';
    // String formattedAdmissionDate = 'N/A';

    // final dischargeDateRaw = firstDischarge['Discharge_date'];
    // final dischargeTimeRaw = firstDischarge['Discharge_time'];
    // final admissionDateRaw = registration['Admission_date'];

    // if (dischargeDateRaw != null && dischargeTimeRaw != null) {
    //   try {
    //     final parsedDischargeDate = DateTime.parse(dischargeDateRaw);
    //     final parsedDischargeTime = DateTime.parse(dischargeTimeRaw);

    //     dischargeDateTime = DateTime(
    //       parsedDischargeDate.year,
    //       parsedDischargeDate.month,
    //       parsedDischargeDate.day,
    //       parsedDischargeTime.hour,
    //       parsedDischargeTime.minute,
    //     );

    //     formattedDischargeDate = _formatDate(dischargeDateTime.toIso8601String());
    //     formattedDischargeTime = DateFormat('hh:mm a').format(dischargeDateTime);
    //   } catch (e) {
    //     print('Invalid discharge date/time format: $e');
    //   }
    // }

    // if (admissionDateRaw != null) {
    //   try {
    //     final parsedAdmissionDate = DateTime.parse(admissionDateRaw);
    //     formattedAdmissionDate = _formatDate(parsedAdmissionDate.toIso8601String());
    //   } catch (e) {
    //     print('Invalid admission date format: $e');
    //   }
    // }
    DateTime? dischargeDateTime;
    String formattedDischargeDate = 'N/A';
    String formattedDischargeTime = 'N/A';
    String formattedAdmissionDate = 'N/A';

    final dischargeDateRaw = firstDischarge['Discharge_date'];
    final dischargeTimeRaw = firstDischarge['Discharge_time'];
    final admissionDateRaw = registration['Admission_date'];

    if (dischargeDateRaw != null && dischargeTimeRaw != null) {
      try {
        dischargeDateTime =
            mergeDateAndTime(dischargeDateRaw, dischargeTimeRaw);
        formattedDischargeDate = formatDate(dischargeDateTime);
        formattedDischargeTime = formatTime(dischargeDateTime);
      } catch (e) {
        print('Invalid discharge date/time format: $e');
      }
    }

    if (admissionDateRaw != null) {
      try {
        final parsedAdmissionDate = DateTime.parse(admissionDateRaw);
        formattedAdmissionDate = formatDate(parsedAdmissionDate);
      } catch (e) {
        print('Invalid admission date format: $e');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Discharge Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader("PATIENT INFORMATION"),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.black26),
            children: [
              TableRow(children: [
                _buildTableCell("Admission No"),
                _buildTableCell("Patient ID"),
                _buildTableCell("Ward No"),
                _buildTableCell("Bed No"),
              ]),
              TableRow(children: [
                _buildTableCell(admissionNo),
                _buildTableCell(patientId),
                _buildTableCell(wardNo),
                _buildTableCell(bedNo),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          _buildFormRow("Name", userData['Name']),
          _buildFormRow(
              "Age / Gender", "${userData['Age']} / ${userData['Gender']}"),
          _buildFormRow("Address", userData['Address']),
          _buildFormRow("Mobile No", userData['Contact_number']),
          _buildFormRow("CNIC", userData['CNIC']),
          _buildFormRow("Date of Admission", formattedAdmissionDate),
          _buildFormRow("Date of Discharge", formattedDischargeDate),
          const SizedBox(height: 20),
          _sectionHeader("HISTORY"),
          const SizedBox(height: 10),
          _buildTextField(registration['Receiving_note'] ?? 'N/A'),
          const SizedBox(height: 20),
          _sectionHeader("INVESTIGATIONS"),
          const SizedBox(height: 12),
          _subSectionHeader("1. REPORT FINDINGS"),
          const SizedBox(height: 6),
          _buildFormRow("CT Scan", firstDischarge['CT_scan']),
          _buildFormRow("MRI", firstDischarge['MRI']),
          _buildFormRow("Other Reports", firstDischarge['Other_reports']),
          _buildFormRow(
              "Diagnosis Based on Report", registration['Associate_diagnosis']),
          const SizedBox(height: 14),
          _subSectionHeader("2. SURGERY (IF ANY)"),
          const SizedBox(height: 6),
          _buildFormRow("Surgery", firstDischarge['Surgery']),
          _buildFormRow(
              "Operative Findings", firstDischarge['Operative_findings']),
          _buildFormRow("Biopsy Report", firstDischarge['Biopsy']),
          const SizedBox(height: 20),
          _sectionHeader("DISCHARGE TREATMENT"),
          const SizedBox(height: 10),
          _buildFormRow("Condition at the Time of Discharge",
              firstDischarge['Condition_at_discharge']),
          _buildFormRow(
              "Discharge Treatment", firstDischarge['Discharge_treatment']),
          _buildFormRow("Follow-up", firstDischarge['Follow_up']),
          _buildFormRow("Instructions", firstDischarge['Instructions']),
          const SizedBox(height: 20),
          _buildFormRow("Disposal Status", registration['Disposal_status']),
          _buildFormRow("Discharged By", "Dr. $doctor"),
          _buildFormRow("Date & Time",
              '$formattedDischargeDate | $formattedDischargeTime'),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // Widget _buildFormRow(String title, dynamic value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 6.0),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Expanded(flex: 3, child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.bold))),
  //         const SizedBox(width: 8),
  //         Expanded(flex: 7, child: Text(value != null ? value.toString() : 'N/A')),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFormRow(String title, dynamic value) {
    // Check if the title is "Disposal Status"
    String displayValue;
    if (title == "Disposal Status") {
      // If it's "Disposal Status", show "Not Discharge" if value is null
      displayValue = value != null ? value.toString() : "Not Discharge";
    } else {
      // For all other rows, show "N/A" if value is null
      displayValue = value != null ? value.toString() : "N/A";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 3,
              child: Text('$title:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
              flex: 7,
              child: Text(displayValue)), // Display the conditional value
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.blueGrey[100],
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[900],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _subSectionHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.blueGrey[800],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(String value) {
    return TextFormField(
      initialValue: value,
      maxLines: null,
      readOnly: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(10),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(dateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return 'N/A';
    }
  }
}
