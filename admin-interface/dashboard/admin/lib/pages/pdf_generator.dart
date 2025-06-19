import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../helper/downloadLocation.dart';

class PdfGenerator {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> patientDetails;

  PdfGenerator({required this.userData, required this.patientDetails});

  Future<String> generatePdf({String? customDirectory}) async {
    final pdf = pw.Document();
    final admissionId = patientDetails["Admission_no"];
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Discharge Summary",
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Patient Details",
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            detailRow("Name", userData["Name"]),
            detailRow("Age", userData["Age"]),
            detailRow("Gender", userData["Gender"]),
            detailRow("Phone No", userData["Contact_number"]),
            detailRow(
                "Alternate Contact", userData["Alternate_contact_number"]),
            detailRow("Address", userData["Address"]),
            pw.SizedBox(height: 10),
            pw.Text("Admission Details",
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            detailRow("Admission No", patientDetails["Admission_no"]),
            detailRow("Admission Date", patientDetails["Admission_date"]),
            detailRow("Admission Time", patientDetails["Admission_time"]),
            detailRow("Mode of Admission", patientDetails["Mode_of_admission"]),
            detailRow("Ward No", patientDetails["Ward_no"]),
            detailRow("Bed No", patientDetails["Bed_no"]),
            detailRow("Doctor Name", patientDetails["DoctorName"]),
            detailRow("Doctor ID", patientDetails["Admitted_under_care_of"]),
            pw.SizedBox(height: 10),
            pw.Text(" History & Status",
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            detailRow("Receiving Notes", patientDetails["Receiving_note"]),
            detailRow("Primary Diagnosis", patientDetails["Primary_diagnosis"]),
            detailRow(
                "Associate Diagnosis", patientDetails["Associate_diagnosis"]),
            detailRow("Procedure", patientDetails["Procedure"]),
            detailRow("Summary", patientDetails["Summary"]),
            detailRow("Disposal Status", patientDetails["Disposal_status"]),
            detailRow("Discharge Date", patientDetails["Discharge_date"]),
            detailRow("Discharge Time", patientDetails["Discharge_time"]),
          ],
        ),
      ),
    );
    print("User Data: $userData");

    // ✅ Use custom directory if provided, otherwise use default location
    String filePath;
    if (customDirectory != null && customDirectory.isNotEmpty) {
      filePath = "$customDirectory/DS_$admissionId.pdf";
    } else {
      final defaultDir = await getApplicationDocumentsDirectory();
      filePath = "${defaultDir.path}/DS_$admissionId.pdf";
    }

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    print("PDF saved at: $filePath");
    return filePath;
  }

  pw.Widget detailRow(String key, dynamic value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("$key: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Expanded(
          child: pw.Text(
            value.toString(),
            overflow: pw.TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}
