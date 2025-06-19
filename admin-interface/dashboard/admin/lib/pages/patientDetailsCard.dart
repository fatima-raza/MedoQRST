import 'package:flutter/material.dart';

Widget buildPatientDetailsCard(Map<String, dynamic> userData) {
  return Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Divider(),
          detailRow("Name", userData["Name"]),
          detailRow("Age", userData["Age"].toString()),
          detailRow("Gender", userData["Gender"]),
          detailRow("Phone No", userData["Contact_number"]),
          detailRow("Alternate Contact", userData["Alternate_contact_number"]),
          detailRow("Address", userData["Address"]),
        ],
      ),
    ),
  );
}

Widget buildAdmissionDetailsCard(Map<String, dynamic> patientDetails) {
  return Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admission Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Divider(),
          detailRow("Admission No", patientDetails["Admission_no"]),
          detailRow("Admission Date", patientDetails["Admission_date"]),
          detailRow("Admission Time", patientDetails["Admission_time"]),
          detailRow("Mode of Admission", patientDetails["Mode_of_admission"]),
          detailRow("Ward No", patientDetails["Ward_no"]),
          detailRow("Bed No", patientDetails["Bed_no"].toString()),
          detailRow("Doctor Name", patientDetails["DoctorName"]),
          detailRow("Doctor ID", patientDetails["Admitted_under_care_of"]),
        ],
      ),
    ),
  );
}

Widget buildHistoryAndStatusCard(Map<String, dynamic> patientDetails) {
  return Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History & Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Divider(),
          detailRow("Receiving Notes", patientDetails["Receiving_note"]),
          detailRow("Primary Diagnosis", patientDetails["Primary_diagnosis"]),
          detailRow(
              "Associate Diagnosis", patientDetails["Associate_diagnosis"]),
          detailRow("Procedure", patientDetails["Procedure"]),
          detailRow("Summary", patientDetails["Summary"]),
          detailRow("Disposal Status", patientDetails["Disposal_status"]),
        ],
      ),
    ),
  );
}

Widget detailRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(value ?? '--'),
      ],
    ),
  );
}
