import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';

class ContactInfo extends StatefulWidget {
  final String admissionNumber; // Added to receive from previous form
  final bool isEditable; // Added to control editability
  final Function(String, Map<String, dynamic>)?
      onNext; // Modified to match your pattern

  const ContactInfo({
    super.key,
    required this.admissionNumber,
    required this.isEditable,
    this.onNext,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ContactInfoState createState() => _ContactInfoState();
}

class _ContactInfoState extends State<ContactInfo> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Controllers for the text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Focus Nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _relationshipFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _submitFocusNode = FocusNode();

  bool _isEditable = false; // Local variable to manage editability

  @override
  void initState() {
    super.initState();
    _isEditable = widget.isEditable; // Initialize local state
  }

  @override
  void dispose() {
    // Dispose all focus nodes
    _nameFocusNode.dispose();
    _relationshipFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _submitFocusNode.dispose();

    // Dispose controllers
    nameController.dispose();
    relationshipController.dispose();
    phoneController.dispose();
    addressController.dispose();

    super.dispose();
  }

  Future<void> saveContactInfoToDatabase() async {
    if (_formKey.currentState!.validate()) {
      try {
        print('Current admission number: ${widget.admissionNumber}');

        final response = await ApiService().storeEmergencyContactInfo({
          'admissionNo': widget.admissionNumber,
          'name': nameController.text,
          'relationship': relationshipController.text,
          'contactNo': phoneController.text,
          'address': addressController.text,
        });

        // Add debug print to see raw response
        print('Full API Response: $response');

        if (response != null) {
          // Show centered dialog
          showDialog(
            context: context,
            barrierDismissible: false, // User can't tap outside to close
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Patient Successfully Admitted!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Admission Number:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    widget.admissionNumber,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          );

          // Auto-close after 3 seconds and return to dashboard
          Future.delayed(Duration(seconds: 3), () {
            Navigator.of(context).pop(); // Close dialog
            if (widget.onNext != null) {
              widget.onNext!('', {}); // Empty route triggers default case
            }
          });
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            "Patient Registration",
            style: GoogleFonts.roboto(fontSize: 24, color: Colors.grey),
          ),
        ),
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
                        'Emergency Contact Information',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          color: const Color(0xFF103783),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      enabled: _isEditable,
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
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: relationshipController,
                      enabled: _isEditable,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Relationship is required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      enabled: _isEditable,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone no. (e.g. 92XXXXXXXXXX)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r"^\d{12}$").hasMatch(value)) {
                            return 'Enter a valid 12-digit phone number';
                          }
                        } else {
                          return 'Contact number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      enabled: _isEditable,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed:
                            _isEditable ? saveContactInfoToDatabase : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF103783),
                        ),
                        child: Text(
                          'Complete!',
                          style: GoogleFonts.roboto(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ))
      ],
    ));
  }
}
