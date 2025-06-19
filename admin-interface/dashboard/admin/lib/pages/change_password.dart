import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;

  // Visibility toggles for password fields
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final response = await ApiService().changeAdminPassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );

      if (response['success'] == true) {
        setState(() {
          _success = response['message'] ?? "Password changed successfully";
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        setState(() {
          _error = response['error'] ?? "Failed to change password";
        });
      }
    } catch (e) {
      setState(() {
        _error = "An unexpected error occurred";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Change Password',
          style: GoogleFonts.roboto(
            color: const Color.fromARGB(255, 122, 121, 121),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Change Password For Admin Account',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF103783),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (_success != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _success!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        TextFormField(
                          controller: _oldPasswordController,
                          obscureText: !_oldPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Old Password',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _oldPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _oldPasswordVisible = !_oldPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter old password'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_newPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _newPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _newPasswordVisible = !_newPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Enter new password';
                            }
                            if (val.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!val.contains(RegExp(r'[0-9]'))) {
                              return 'Password must contain a number';
                            }
                            if (!val.contains(RegExp(r'[A-Z]'))) {
                              return 'Password must contain an uppercase letter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Re-enter new password';
                            }
                            if (val != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password must be at least 8 characters and include:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '- At least one number\n- At least one uppercase letter',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleChangePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF103783),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
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
        ),
      ),
    );
  }
}
