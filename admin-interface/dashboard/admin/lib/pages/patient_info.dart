import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/pages/admission_info.dart';

class PatientInfo extends StatefulWidget {
  final Map<String, dynamic> summaryData;
  final void Function(String, Map<String, dynamic>)? onNext;
  final bool isEditable;

  const PatientInfo({
    Key? key,
    required this.onNext,
    required this.summaryData,
    required this.isEditable,
  }) : super(key: key);

  @override
  State<PatientInfo> createState() => _PatientInfoState();
}

class _PatientInfoState extends State<PatientInfo> {
  final _formKey = GlobalKey<FormState>(); // Add form key

  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  // FocusNodes for text fields
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode ageFocusNode = FocusNode();
  final FocusNode addressFocusNode = FocusNode();
  final FocusNode phoneNoFocusNode = FocusNode();
  final FocusNode cnicFocusNode = FocusNode();

  // Gender dropdown
  String? selectedGender;
  final List<String> genderOptions = ['M', 'F'];
  Map<String, dynamic> _initialPatientData = {};
  bool _isEditable = false; // Local variable to manage editability
  Map<String, dynamic> _updatedPatientData = {};
  String PatientID = '';

  String _formatGender(String? gender) {
    if (gender == null) return 'N/A';
    return gender.toUpperCase() == 'M' ? 'Male' : 'Female';
  }

  @override
  void initState() {
    super.initState();

    print("Summary Data at initState: ${widget.summaryData}");

    if (widget.summaryData.isNotEmpty &&
        widget.summaryData["patientData"] != null) {
      _initialPatientData =
          Map<String, dynamic>.from(widget.summaryData["patientData"]);
    }

    setState(() {
      PatientID = _initialPatientData["UserID"] ?? '';
    });

    print("Updated PatientID: $PatientID");
    print("Summary Data at initState: ${widget.summaryData}");
    print('widget.isEditable at initState: ${widget.isEditable}');
    _isEditable = widget.isEditable;
    print('_isEditable after assignment: $_isEditable');
    print("Received summaryData: ${widget.summaryData}");

    print('Initial Patient Data: $_initialPatientData');
    print('Summary Data from API: ${widget.summaryData}');

    // Check if summaryData has existing patient information
    if (widget.summaryData.isNotEmpty) {
      nameController.text = widget.summaryData['patientData']?['Name'] ?? "";
      ageController.text =
          widget.summaryData['patientData']?['Age']?.toString() ?? "";
      selectedGender = widget.summaryData['patientData']?['Gender'];
      phoneNoController.text =
          widget.summaryData['patientData']?['Contact_number'] ?? '';
      addressController.text =
          widget.summaryData['patientData']?['Address'] ?? '';
      cnicController.text = widget.summaryData['patientData']?['CNIC'] ?? '';

      _initialPatientData = {
        "Name": nameController.text,
        "Age": ageController.text,
        "Gender": selectedGender,
        "Contact_number": phoneNoController.text,
        "Address": addressController.text,
        "CNIC": cnicController.text,
      };
    }
  }

  bool _hasPatientDataChanged() {
    print('Checking data changes...');
    print('Initial Data: $_initialPatientData');

    Map<String, dynamic> currentData = {
      "Name": nameController.text,
      "Age": ageController.text,
      "Gender": selectedGender,
      "Contact_number": phoneNoController.text,
      "Address": addressController.text,
      "CNIC": cnicController.text,
    };

    print('Current Data: $currentData');

    bool changed = false;
    for (var key in _initialPatientData.keys) {
      if (_initialPatientData[key] != currentData[key]) {
        debugPrint(
            "flutter: Field '$key' changed from '${_initialPatientData[key]}' to '${currentData[key]}'");
        changed = true;
      }
    }
    debugPrint("flutter: _hasPatientDataChanged result: $changed");
    return changed;
  }

  void _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    String? patientId = await _savePatientInfoToDatabase();

    if (patientId != null) {
      print('Navigating to next step with PatientID: $patientId');
      widget.onNext?.call('/admission_info', {'patientId': patientId});
    } else {
      print('Patient ID is null. Navigation not triggered.');
    }
  }

  // Method to save patient info to the database
  Future<String?> _savePatientInfoToDatabase() async {
    try {
      final apiService = ApiService(); // Create an instance of ApiService

      // Prepare the patient data
      Map<String, dynamic> patientData = {
        "Name": nameController.text,
        "Age": int.tryParse(ageController.text) ?? 0, // Convert age to int
        "Gender": selectedGender,
        "Contact_number": phoneNoController.text.isNotEmpty
            ? phoneNoController.text
            : null, // Allow null
        "Address": addressController.text.isNotEmpty
            ? addressController.text
            : null, // Allow null
        "CNIC": cnicController.text, // required cnic field
      };

      // additional
      print('Sending request to API...');
      print(
          'Name: ${nameController.text}, Age: ${ageController.text}, Gender: $selectedGender, Contact_number: ${phoneNoController.text}, Address: ${addressController.text}, CNIC: ${cnicController.text}');

      // Debugging: Print summaryData before extracting UserID
      print("Extracting UserID from summaryData: ${widget.summaryData}");

      if (widget.summaryData.isNotEmpty &&
          widget.summaryData['patientData']?['UserID'] != null) {
        String? patientId = widget.summaryData['patientData']?['UserID'];

        if (patientId != null && _hasPatientDataChanged()) {
          bool updated = await apiService.updatePatient(patientId, patientData);

          if (updated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "Details of patient with ID '$patientId' have been updated successfully!"),
                  backgroundColor: Colors.green),
            );
            return patientId;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Failed to update patient details"),
                  backgroundColor: Colors.red),
            );
            return null;
          }
        } else {
          print(
              "No changes detected, returning existing PatientID: $patientId");
          return patientId; // No changes, return existing ID
        }
      } else {
        // no existing patient, create a new one
        String? newPatientId = await apiService.createPatient(patientData);

        if (newPatientId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Patient Registered! ID: $newPatientId"),
                backgroundColor: Colors.green),
          );
          return newPatientId;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Failed to register patient"),
                backgroundColor: Colors.red),
          );
          return null;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error saving patient data. Please try again."),
            backgroundColor: Colors.red),
      );
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_updatedPatientData.isEmpty) {
      _updatedPatientData =
          Map<String, dynamic>.from(widget.summaryData["patientData"] ?? {});
      debugPrint(
          'flutter: _initialPatientData initialized: $_initialPatientData');
    }

    // Debugging print statements
    print(
        "Route Name at didChangeDependencies: ${ModalRoute.of(context)?.settings.name}");
    print("Summary Data at didChangeDependencies: ${widget.summaryData}");
    print("isEditable in didChangeDependencies: ${widget.isEditable}");
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    addressController.dispose();
    phoneNoController.dispose();
    cnicController.dispose();

    nameFocusNode.dispose();
    ageFocusNode.dispose();
    addressFocusNode.dispose();
    phoneNoFocusNode.dispose();
    cnicFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Route Name at build: ${ModalRoute.of(context)?.settings.name}");
    print("Summary Data at build: ${widget.summaryData}");
    print("PatientInfo received: ${widget.summaryData}"); // Debugging line
    print("Received in PatientInfo -> isEditable: ${widget.isEditable}");

    return Material(
      child: Column(children: [
        // Patient Registration title at the top
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            "Patient Registration",
            style: GoogleFonts.roboto(
              fontSize: 24,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Expanded so that the form remains in the center
        Expanded(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(50),
              width: 500, // or whatever width you like
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
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Patient Information Form',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            color: const Color(0xFF103783),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(height: 10),

                      // Name field
                      TextFormField(
                        controller: nameController,
                        focusNode: nameFocusNode,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () => ageFocusNode.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
                            return 'Only letters and spaces allowed';
                          }
                          return null;
                        },
                        enabled: _isEditable,
                      ),
                      const SizedBox(height: 10),

                      // Age and Gender
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Age',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Age is required';
                                  }
                                  int? age = int.tryParse(value);
                                  if (age == null || age < 0) {
                                    return 'Enter a valid age';
                                  }
                                  return null;
                                },
                                enabled: _isEditable,
                              ),
                            ),
                            SizedBox(width: 10), // Space between fields
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedGender,
                                onChanged: _isEditable
                                    ? (value) {
                                        setState(() {
                                          selectedGender = value;
                                        });
                                      }
                                    : null,
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isEditable
                                          ? Colors.black
                                          : Colors.grey, // Change border color
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isEditable
                                          ? Colors.black
                                          : Colors.grey, // Match text fields
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors
                                          .grey, // Force grey when disabled
                                    ),
                                  ),
                                ),
                                items: genderOptions.map((String gender) {
                                  return DropdownMenuItem<String>(
                                    value: gender,
                                    child: Text(_formatGender(gender)),
                                  );
                                }).toList(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Select gender';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // CNIC
                      TextFormField(
                        controller: cnicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CNIC',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'CNIC is required';
                          }
                          if (!RegExp(r"^\d{13}$").hasMatch(value)) {
                            return 'Enter a valid 13-digit CNIC number';
                          }
                          return null;
                        },
                        enabled: _isEditable,
                      ),
                      const SizedBox(height: 10),

                      // Phone number
                      TextFormField(
                        controller: phoneNoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone No',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r"^\d{12}$").hasMatch(value)) {
                              return 'Enter a valid 12-digit phone number';
                            }
                          }
                          return null;
                        },
                        enabled: _isEditable,
                      ),
                      const SizedBox(height: 10),

                      // Address field
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditable,
                      ),
                      const SizedBox(height: 20),

                      // Next button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isEditable ? _validateAndProceed : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF103783),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                          ),
                          child: Text(
                            'Next',
                            style: GoogleFonts.roboto(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
