import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';

class StaffRegister extends StatefulWidget {
  final VoidCallback? onNext;

  const StaffRegister({super.key, this.onNext});

  @override
  _StaffRegisterState createState() => _StaffRegisterState();
}

class _StaffRegisterState extends State<StaffRegister> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();

  String selectedRole = "Doctor"; // Default role selection
  String? selectedGender; // Holds "M" or "F"
  String? _departmentValidationError;
  int? selectedDepartmentId;
  List<Map<String, dynamic>> departmentList = [];
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isSubmitting = false;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    fetchDepartments(); // <-- Call your function here
  }

  Future<void> validateAndProceed() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      _isSubmitting = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    if (_departmentValidationError != null) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    await saveStaffInfoToDatabase(); // capture generated ID
    if (widget.onNext != null) widget.onNext!();
  }

  Future<void> saveStaffInfoToDatabase() async {
    try {
      final apiService = ApiService();

      Map<String, dynamic> staffData = {
        'name': nameController.text,
        "age": int.tryParse(ageController.text) ?? 0,
        'gender': selectedGender,
        'cnic': cnicController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'address': addressController.text,
        'role': selectedRole,
        if (selectedRole == "Doctor") ...{
          'department': selectedDepartmentId,
          'specialization': specializationController.text,
        }
      };

      // Convert response if it's a JSON string
      String? userId = selectedRole == "Doctor"
          ? await apiService.createDoctor(staffData)
          : await apiService.createNurse(staffData);

      if (userId != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Center(
                child: Icon(Icons.check_circle, color: Colors.green, size: 48)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Registration Successful!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center),
                SizedBox(height: 16),
                Text('${selectedRole} ID:',
                    style: TextStyle(color: Colors.grey)),
                Text(userId,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700])),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isSubmitting = false;
                  });
                  _clearForm();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Center(
                child: Icon(
              Icons.error,
              color: Colors.red, // Red icon for failure
              size: 48,
            )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Registration Failed!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // Larger font size for failure message
                    color: const Color(
                        0xFF103783), // Red color for the failure message
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Please try again.',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 119, 118, 118),
                    fontSize: 16, // Increased font size for context
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isSubmitting = false;
                  });
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }

      return;
    } catch (error) {
      // Handle unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${error.toString()}")),
      );
    }
    String genderToStore = selectedGender ?? "";
  }

  // Clears the form fields
  void _clearForm() {
    // Recreate the form key to reset validation state
    _formKey = GlobalKey<FormState>();
    _autovalidateMode = AutovalidateMode.disabled;

    nameController.clear();
    ageController.clear();
    cnicController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    departmentController.clear();
    specializationController.clear();

    selectedGender = null;
    selectedDepartmentId = null;
    _departmentValidationError = null;

    setState(() {});
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter Full Name';
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value))
      return 'Only alphabets and spaces allowed';
    return null;
  }

  String? validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Please enter Age';
    if (int.tryParse(value) == null || int.parse(value) < 0)
      return 'Enter a valid age';
    return null;
  }

  String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a Gender';
    }
    return null;
  }

  String? validateCNIC(String? value) {
    if (value == null || value.isEmpty) return 'Please enter CNIC';
    if (!RegExp(r'^\d{13}$').hasMatch(value))
      return 'Invalid CNIC. Must be exactly 13 digits.';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Please enter Contact no.";
    if (!RegExp(r'^\d{12}$').hasMatch(value))
      return 'Invalid phone number. Must be 12 digits.';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter Email';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(value))
      return 'Invalid email. Only Gmail addresses allowed.';
    return null;
  }

  String? validateDepartment(int? value) {
    if (selectedRole == "Doctor" && value == null) {
      return 'Please select a department'; // Return error message directly
    }
    return null; // No error
  }

  Future<void> fetchDepartments() async {
    try {
      final response = await ApiService().fetchDepartments('');
      print('API Response: $response');

      departmentList = response;

      final ids = departmentList.map((e) => e['DepartmentID']).toList();
      print('Department IDs: $ids');

      if (ids.toSet().length != ids.length) {
        throw Exception('Duplicate department IDs found. IDs: $ids');
      }
      setState(() {
        departmentList = response;
      });
    } catch (e) {
      print('Error fetching departments: $e');
      setState(() {
        departmentList = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading departments: ${e.toString()}')));
    }
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool isRequired = true, String? Function(String?)? validator}) {
    return Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: SizedBox(
            height: 65,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.roboto(
                  color: Color.fromARGB(255, 122, 121, 121), // Label color
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 122, 121, 121),
                    width: 1.5, // Thin border
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 122, 121, 121), // Normal border
                    width: 1.0, // Adjust to match dropdown
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 2, 34,
                        59), // Matches text field focus color // Border color when field is selected
                    width: 1.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(
                        0xFF103783), // Red border when validation fails
                    width: 1.0, // Keep the thin border
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(
                        0xFF103783), // Red border when selected & invalid
                    width: 1.0,
                  ),
                ),
                focusColor: Color.fromARGB(255, 122, 121, 121),
              ),
              validator: validator,
              onChanged: (value) {
                if (_submitted) {
                  setState(() {}); // Revalidate live when user types
                }
              },
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (departmentList.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(
          color: Colors.grey,
        )),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'Staff Registration',
              style: GoogleFonts.roboto(
                color: const Color.fromARGB(255, 122, 121, 121),
              ),
            ),
          ),
          backgroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert), // Three vertical dots
              onSelected: (String value) async {
                // Check if any field has data
                final hasData = nameController.text.isNotEmpty ||
                    ageController.text.isNotEmpty ||
                    cnicController.text.isNotEmpty ||
                    phoneController.text.isNotEmpty ||
                    emailController.text.isNotEmpty ||
                    selectedGender != null ||
                    addressController.text.isNotEmpty ||
                    (selectedRole == "Doctor"
                        ? (departmentController.text.isNotEmpty ||
                            specializationController.text.isNotEmpty)
                        : false);

                if (hasData) {
                  final shouldProceed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Discard changes?'),
                      content:
                          Text('Switching roles will clear all entered data'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Continue'),
                        ),
                      ],
                    ),
                  );

                  if (shouldProceed != true) return;
                }

                _clearForm();
                setState(() => selectedRole = value);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: "Doctor",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Doctor"),
                      if (selectedRole == "Doctor")
                        Icon(Icons.check, color: const Color(0xFF103783)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: "Nurse",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Nurse"),
                      if (selectedRole == "Nurse")
                        Icon(Icons.check, color: const Color(0xFF103783)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Stack(children: [
            SingleChildScrollView(
              child: Container(
                width: 800,
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          '$selectedRole Registration Form',
                          style: GoogleFonts.roboto(
                              fontSize: 20, color: const Color(0xFF103783)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // First Row: Full Name & Age
                      Row(
                        children: [
                          buildTextField('Full Name', nameController,
                              validator: validateName),
                          buildTextField('Age', ageController,
                              validator: validateAge),
                        ],
                      ),

                      // Second Row: Gender & CNIC
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                child: SizedBox(
                                  height: 65,
                                  child: DropdownButtonFormField<String>(
                                    value: selectedGender,
                                    decoration: InputDecoration(
                                      labelText: 'Gender',
                                      labelStyle: GoogleFonts.roboto(
                                        color:
                                            Color.fromARGB(255, 122, 121, 121),
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 122, 121, 121),
                                          width:
                                              1.0, // Make it same as text field
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 122, 121, 121),
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color.fromARGB(
                                              255,
                                              2,
                                              34,
                                              59), // Matches text field focus color
                                          width: 1.0,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color(
                                              0xFF103783), // Red for error
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color(0xFF103783),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: "M",
                                        child: Text("Male"),
                                      ),
                                      DropdownMenuItem(
                                        value: "F",
                                        child: Text("Female"),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedGender = value;
                                      });
                                      // Immediately revalidate the form
                                    },
                                    onSaved: (value) {
                                      selectedGender =
                                          value; // Ensure value is stored properly
                                    },
                                    validator: validateGender,
                                  ),
                                )),
                          ),
                          buildTextField('CNIC', cnicController,
                              validator: validateCNIC),
                        ],
                      ),

                      // Third Row: Phone No & Email
                      Row(
                        children: [
                          buildTextField(
                              'Phone no. (e.g. 92XXXXXXXXXX)', phoneController,
                              validator: validatePhone),
                          buildTextField(
                              'Email (e.g. example@gmail.com)', emailController,
                              validator: validateEmail),
                        ],
                      ),

                      // Conditionally show Department & Specialization for Doctors only
                      if (selectedRole == "Doctor") ...[
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                child: SizedBox(
                                  height: 65,
                                  child: departmentList.isEmpty
                                      ? Center(
                                          child: CircularProgressIndicator())
                                      : DropdownButtonFormField<int>(
                                          value:
                                              selectedDepartmentId, // Can be null initially
                                          decoration: InputDecoration(
                                            labelText: 'Department',
                                            // Error text is managed by the validator, so no need for _departmentValidationError here
                                            labelStyle: GoogleFonts.roboto(
                                              color: Color.fromARGB(
                                                  255, 122, 121, 121),
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 122, 121, 121),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          items: departmentList.map((dept) {
                                            return DropdownMenuItem<int>(
                                              value: dept['DepartmentID'],
                                              child:
                                                  Text(dept['Department_name']),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedDepartmentId = value;
                                              // You don't need to set _departmentValidationError here anymore
                                            });
                                          },
                                          // The validator now checks for department selection
                                          validator: validateDepartment,
                                        ),
                                ),
                              ),
                            ),
                            buildTextField(
                                'Specialization', specializationController,
                                isRequired: false),
                          ],
                        ),
                      ],

                      // Fourth Row: Address
                      // Address Field - Left column alone
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                child: SizedBox(
                                  height: 65,
                                  child: TextFormField(
                                    controller: addressController,
                                    decoration: InputDecoration(
                                      labelText: 'Address',
                                      labelStyle: GoogleFonts.roboto(
                                        color:
                                            Color.fromARGB(255, 122, 121, 121),
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 122, 121, 121),
                                          width:
                                              1.0, // Make it same as text field
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 122, 121, 121),
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color.fromARGB(
                                              255,
                                              2,
                                              34,
                                              59), // Matches text field focus color
                                          width: 1.0,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color(
                                              0xFF103783), // Red for error
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color(0xFF103783),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter Address";
                                      }
                                      return null;
                                    },
                                  ),
                                )),
                          ),
                          Expanded(
                              child:
                                  SizedBox()), // Keeps alignment with other fields
                        ],
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _submitted = true;
                                });

                                if (_formKey.currentState!.validate()) {
                                  validateAndProceed();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF103783),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Register',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Container(
                    color: Colors.transparent, // No tint, just blur
                    alignment: Alignment.center,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ]),
        ));
  }
}
