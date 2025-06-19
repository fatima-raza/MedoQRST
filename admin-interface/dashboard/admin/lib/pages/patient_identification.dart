import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/pages/patient_info.dart';
import 'dart:convert';

class PatientIdentification extends StatefulWidget {
  final bool fromBedPage;
  final void Function(String route, Object? patientData) onNext;
  const PatientIdentification(
      {super.key, required this.onNext, required this.fromBedPage});

  @override
  _PatientIdentificationState createState() => _PatientIdentificationState();
}

class _PatientIdentificationState extends State<PatientIdentification> {
  final ApiService _apiService = ApiService();
  final TextEditingController _identifierController = TextEditingController();
  Map<String, dynamic>? selectedPatientData;
  String? _message;
  bool _isLoading = false;
  bool isPatientFound = false;
  bool? fromBedPageFlag = false;

  @override
  void initState() {
    super.initState();
    fromBedPageFlag = widget.fromBedPage;
    print("PatientIdentification loaded with fromBedPage: $fromBedPageFlag");
  }

  Future<void> _searchPatient() async {
    final query = _identifierController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _message = 'Please enter a CNIC or Patient ID.';
        selectedPatientData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _apiService.checkExistingPatient(query);

    print('API Result: $result'); // Debugging line to check the API response
    print(
        'Type of result["data"]: ${result?["data"]?.runtimeType}'); // Debugging line

    setState(() {
      _isLoading = false;
      if (result != null && result['found'] == true) {
        if (result['data'] is Map<String, dynamic>) {
          selectedPatientData = result['data'];
        } else if (result['data'] is String) {
          try {
            selectedPatientData = jsonDecode(result['data']);
          } catch (e) {
            print('JSON decode error: $e');
            selectedPatientData = null;
            _message = 'Invalid patient data received.';
          }
        } else {
          selectedPatientData = null;
          _message = 'Unexpected data format.';
        }
      } else {
        selectedPatientData = null;
        _message = result?['message'] ?? 'No previous record found.';
      }
    });
  }

  void _proceed() {
    if (_identifierController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please enter a valid CNIC or Patient ID before proceeding'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop further execution if no input
    }
    if (widget.fromBedPage) {
      print("Proceeding with Patient Data: $selectedPatientData");
      print(
          'Type of selectedPatientData in _proceed(): ${selectedPatientData.runtimeType}');
      widget.onNext('/patient_info', {
        'isEditable': true,
        'patientData': selectedPatientData ?? {},
      });
    } else {
      print("Error: Bed selection required before proceeding.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check for bed availability first'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'N/A';
    return gender.toUpperCase() == 'M' ? 'Male' : 'Female';
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.roboto(fontSize: 16),
              softWrap: true,
              overflow: TextOverflow.visible, // Ensures full visibility
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed = widget.fromBedPage;
    print('PatientIdentification loaded with fromBedPage: ${fromBedPageFlag}');

    return Material(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              "Patient Registration",
              style: GoogleFonts.roboto(
                fontSize: 24,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          // Pushes the card to the center while keeping heading at the top
          child: Center(
            child: Container(
              width: 400,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search for Patient',
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF103783),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: 'Enter CNIC no. or patient ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _searchPatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF103783),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Search',
                            style: GoogleFonts.roboto(color: Colors.white),
                          ),
                  ),
                  SizedBox(height: 16),
                  if (selectedPatientData != null)
                    Column(
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(Icons.person, 'Patient ID',
                                    selectedPatientData?['UserID']),
                                _infoRow(Icons.account_circle, 'Name',
                                    selectedPatientData?['Name']),
                                _infoRow(Icons.cake, 'Age',
                                    selectedPatientData?['Age']?.toString()),
                                _infoRow(
                                    Icons.male,
                                    'Gender',
                                    _formatGender(
                                        selectedPatientData?['Gender'])),
                                _infoRow(Icons.phone, 'Phone',
                                    selectedPatientData?['Contact_number']),
                                _infoRow(Icons.badge, 'CNIC',
                                    selectedPatientData?['CNIC']),
                                _infoRow(Icons.location_on, 'Address',
                                    selectedPatientData?['Address']),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16), // Added this SizedBox for the gap
                      ],
                    )
                  else if (_message != null) ...[
                    Text(
                      _message!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24), // space after message
                  ],
                  ElevatedButton(
                    onPressed: canProceed ? _proceed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF103783),
                    ),
                    child: Text(
                      'Proceed to registration',
                      style: GoogleFonts.roboto(color: Colors.white),
                    ),
                  ),
                  if (!widget.fromBedPage && selectedPatientData != null)
                    const Text(
                      'Please check for bed availability first.',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }
}
