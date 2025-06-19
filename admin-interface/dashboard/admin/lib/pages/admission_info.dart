import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AdmissionInfo extends StatefulWidget {
  final Function(String, Map<String, dynamic>)? onNext;
  final bool isEditable;
  final String patientId;
  final VoidCallback? onHomeRedirect;

  const AdmissionInfo({
    Key? key,
    required this.patientId,
    this.onNext,
    required this.isEditable,
    this.onHomeRedirect,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AdmissionInfoState createState() => _AdmissionInfoState();
}

class _AdmissionInfoState extends State<AdmissionInfo> {
  // GlobalKey for the Form to manage form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController modeController = TextEditingController();
  final TextEditingController wardNameController = TextEditingController();
  final TextEditingController bedNoController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();

  final FocusNode dateFocusNode = FocusNode();
  final FocusNode modeFocusNode = FocusNode();
  final FocusNode bedFocusNode = FocusNode();
  final FocusNode doctorNameFocusNode = FocusNode();
  final FocusNode wardFocusNode = FocusNode();

  String? selectedMode;
  String? selectedBed;
  String? selectedWard;
  String? selectedDoctorId;
  bool isLoadingBeds = false;
  bool _isEditable = false; // Local variable to manage editability
  List<String> availableBeds = [];
  List<Map<String, dynamic>> wards = [];
  bool noBedsAvailable = false; // Track if current ward has no beds

  @override
  void initState() {
    super.initState();
    _isEditable = widget.isEditable; // Initialize local state
    fetchWardsFromApi();
  }

  @override
  void dispose() {
    dateController.dispose();
    modeController.dispose();
    bedNoController.dispose();
    wardNameController.dispose();
    doctorNameController.dispose();

    // Dispose focus nodes
    dateFocusNode.dispose();
    modeFocusNode.dispose();
    bedFocusNode.dispose();
    doctorNameFocusNode.dispose();
    wardFocusNode.dispose();

    super.dispose();
  }

  Future<void> fetchWardsFromApi() async {
    final wardList = await ApiService().getAllWards();
    if (wardList != null) {
      setState(() {
        wards = wardList;
      });
    }
  }

  Future<void> fetchBedsFromApi(String wardNo) async {
    setState(() {
      isLoadingBeds = true; // Start loadign spinner
      noBedsAvailable = false;
    });

    final bedsData = await ApiService().getAvailableBeds(wardNo);
    print("API Response for Ward $wardNo: $bedsData"); // Debugging

    if (bedsData != null && bedsData['availableBeds'] is List) {
      setState(() {
        availableBeds = (bedsData['availableBeds'] as List<dynamic>)
            .map((bed) => bed.toString()) // Extract bed_number
            .toList();
        selectedBed = null; // Reset selection
        noBedsAvailable = availableBeds.isEmpty;
      });
      print("Available Beds: $availableBeds"); // Debugging
    } else {
      setState(() {
        availableBeds = [];
        selectedBed = null;
        noBedsAvailable = true; // Set flag when no beds
      });
      print("No beds available or incorrect response format");
    }
    setState(() {
      isLoadingBeds = false; // Stop loading spinner
    });
  }

  // Function to validate the form and proceed to next step
  void validateAndProceed() async {
    if (_formKey.currentState!.validate()) {
      String? admissionNumber = await saveAdmissionInfoToDatabase();

      if (admissionNumber != null && widget.onNext != null) {
        print("Debug: Passing admission number $admissionNumber to next form");
        widget.onNext!('/contact_info', {
          'admissionNo': admissionNumber,
        });
      }
    }
  }

  // Function to save admission info to database (placeholder for actual logic)
  Future<String?> saveAdmissionInfoToDatabase() async {
    print("Debug: widget.patientId = ${widget.patientId}");

    final admissionData = {
      'patientId': widget.patientId,
      'dateOfAdmission': dateController.text,
      'modeOfAdmission': selectedMode,
      'wardNo': selectedWard,
      'bedNo': selectedBed != null ? int.parse(selectedBed!) : null,
      'admittedUnderCareOf': selectedDoctorId,
    };
    print("Debug: Sending admission data: ${jsonEncode(admissionData)}");

    final apiService = ApiService();
    final admissionNumber = await apiService.storeAdmissionInfo(admissionData);

    if (admissionNumber != null) {
      print("Debug: Received admission number: $admissionNumber");
      return admissionNumber;
    } else {
      print("Failed to save admission info");
      return null;
    }
  }

  // Function to clear all form fields
  void clearForm() {
    setState(() {
      dateController.clear();
      modeController.clear();
      wardNameController.clear();
      bedNoController.clear();
      doctorNameController.clear();
      selectedMode = null;
      selectedBed = null;
      selectedWard = null;
      selectedDoctorId = null;
      availableBeds = [];
      noBedsAvailable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Column(children: [
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
      Expanded(
          child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(50.0),
          width: 500,
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
                    'Admission Information Form',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      color: const Color(0xFF103783),
                    ),
                  )),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: dateController,
                    enabled: _isEditable,
                    focusNode: dateFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Date of Admission',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            dateController.text =
                                '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                      border: const OutlineInputBorder(),
                      errorStyle:
                          TextStyle(color: Colors.red[700]), // Red error text
                      labelStyle: GoogleFonts.roboto(
                        color: dateFocusNode.hasFocus
                            ? const Color.fromARGB(255, 122, 121, 121)
                            : Colors.grey,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 122, 121, 121),
                          width: 2.0,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date of admission';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    focusNode: modeFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Mode of Admission',
                      border: const OutlineInputBorder(),
                      labelStyle: GoogleFonts.roboto(
                        color: modeFocusNode.hasFocus
                            ? const Color.fromARGB(255, 122, 121, 121)
                            : Colors.grey,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 122, 121, 121),
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isEditable ? Colors.black : Colors.grey,
                        ),
                      ),
                      disabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    value: selectedMode,
                    items: ['from OPD', 'Emergency', 'Referred', 'Transferred']
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode, style: GoogleFonts.roboto()),
                            ))
                        .toList(),
                    onChanged: _isEditable
                        ? (value) {
                            setState(() {
                              selectedMode = value;
                            });
                          }
                        : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mode of admission is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    focusNode: wardFocusNode, // Add focus node if needed
                    decoration: InputDecoration(
                      labelText: 'Ward Name', // Change label to Ward Name
                      border: const OutlineInputBorder(),
                      labelStyle: GoogleFonts.roboto(
                        color: wardFocusNode.hasFocus
                            ? const Color.fromARGB(255, 122, 121, 121)
                            : Colors.grey,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 122, 121, 121),
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isEditable
                              ? Colors.black
                              : Colors
                                  .grey, // Change color based on _isEditable
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey, // Grey border when disabled
                        ),
                      ),
                    ),
                    value: selectedWard,
                    items: wards.map((ward) {
                      return DropdownMenuItem<String>(
                        value: ward['wardNo'], // Store Ward No internally
                        child: Text(ward['wardName'],
                            style: GoogleFonts.roboto()), // Show Ward Name
                      );
                    }).toList(),
                    onChanged: _isEditable
                        ? (value) {
                            setState(() {
                              selectedWard = value; // Store the Ward No
                              selectedBed = null; // Reset bed selection
                              fetchBedsFromApi(
                                  value!); // Fetch beds for selected ward
                            });
                          }
                        : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a ward';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  isLoadingBeds
                      ? const CircularProgressIndicator()
                      : selectedWard == null
                          ? const SizedBox()
                          : availableBeds.isEmpty
                              ? const Text(
                                  "No available beds in this ward.",
                                  style: TextStyle(color: Colors.red),
                                )
                              : DropdownButtonFormField<String>(
                                  focusNode: bedFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Bed No',
                                    border: const OutlineInputBorder(),
                                    labelStyle: GoogleFonts.roboto(
                                      color: bedFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 122, 121, 121)
                                          : Colors.grey,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color.fromARGB(
                                            255, 122, 121, 121),
                                        width: 2.0,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isEditable
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  value: selectedBed,
                                  items: availableBeds
                                      .map((bed) => DropdownMenuItem(
                                            value: bed,
                                            child: Text(bed,
                                                style: GoogleFonts.roboto()),
                                          ))
                                      .toList(),
                                  onChanged: _isEditable
                                      ? (value) {
                                          setState(() {
                                            selectedBed = value;
                                          });
                                        }
                                      : null,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a bed number';
                                    }
                                    return null;
                                  },
                                ),
                  const SizedBox(height: 10),
                  TypeAheadFormField<Map<String, dynamic>>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: doctorNameController,
                      enabled: _isEditable,
                      focusNode: doctorNameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Admitted Under the Care of',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.roboto(
                          color: doctorNameFocusNode.hasFocus
                              ? const Color.fromARGB(255, 122, 121, 121)
                              : Colors.grey,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 122, 121, 121),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) {
                        return []; // Return empty list if no input
                      }
                      return await ApiService().fetchDoctors(pattern);
                    },
                    itemBuilder: (context, Map<String, dynamic> suggestion) {
                      return ListTile(
                        title: Text(
                            suggestion['Name']), // Show doctor name in dropdown
                      );
                    },
                    onSuggestionSelected:
                        (Map<String, dynamic> selectedDoctor) {
                      setState(() {
                        doctorNameController.text =
                            selectedDoctor['Name']; // Display name in UI
                        selectedDoctorId = selectedDoctor[
                            'DoctorID']; // Store DoctorID for submission
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a doctor';
                      }
                      return null;
                    },
                    noItemsFoundBuilder: (context) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0), // Reduce vertical padding
                      child: Text(
                        'No Items Found!',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // In the build method, modify the button section like this:
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (noBedsAvailable &&
                            selectedWard != null) // Only show when no beds
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ElevatedButton(
                              onPressed: () {
                                clearForm();
                                if (widget.onHomeRedirect != null) {
                                  widget.onHomeRedirect!(); // Use the callback
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                              ),
                              child: Text(
                                'Go to Home Page',
                                style: GoogleFonts.roboto(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: (noBedsAvailable && selectedWard != null)
                              ? null
                              : _isEditable
                                  ? validateAndProceed
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF103783),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                          ),
                          child: Text(
                            'Next',
                            style: GoogleFonts.roboto(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ))
    ]));
  }
}
