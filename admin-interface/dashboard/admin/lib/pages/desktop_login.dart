import 'package:admin/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/network_client.dart';

class LoginDesktop extends StatefulWidget {
  const LoginDesktop({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginDesktopState createState() => _LoginDesktopState();
}

class _LoginDesktopState extends State<LoginDesktop> {
  bool _isChecked = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Controllers for TextFields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _apiService = ApiService();

  
  void _login() async {
  // Prevent multiple simultaneous logins
  if (_isLoading) return;

  setState(() {
    _isLoading = true;
  });

  try {
    String enteredUsername = _usernameController.text.trim();
    String enteredPassword = _passwordController.text.trim();

    // Check for blank username or password
    if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Input Required"),
          content: const Text("Please enter both username and password."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Color(0xFF103783))),
            ),
          ],
        ),
      );
      return;
    }

    // Call the login API via ApiService
    bool isSuccess = await _apiService.adminLogin(enteredUsername, enteredPassword);

    if (isSuccess) {
      final uri = Uri.parse(NetworkClient.cookieDomain);

      if (ApiService.cookieJar != null) {
        final cookies = await ApiService.cookieJar!.loadForRequest(uri);
        await ApiService.cookieJar!.saveFromResponse(uri, cookies);
      }

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(loggedValue: 1),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Login Failed"),
          content: const Text("Invalid username or password. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Color(0xFF103783))),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text("An error occurred: ${e.toString()}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF103783))),
          ),
        ],
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.asset(
                'assets/MDS.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
       
        Expanded(
  child: Container(
    constraints: const BoxConstraints(maxWidth: 450),
    padding: const EdgeInsets.symmetric(horizontal: 50),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 17,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to your account',
          style: GoogleFonts.inter(
            fontSize: 23,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        // Username TextField
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            labelStyle: TextStyle(color: Colors.black),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
          cursorColor: Colors.black,
          textInputAction: TextInputAction.next, // Moves to next field on Enter
          onSubmitted: (_) => FocusScope.of(context).nextFocus(), // Auto-focus Password
        ),
        const SizedBox(height: 20),
        // Password TextField
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: const TextStyle(color: Colors.black),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          obscureText: _obscurePassword,
          cursorColor: Colors.black,
          textInputAction: TextInputAction.go, // Triggers login on Enter
          onSubmitted: (_) => _login(), // Executes login on Enter
        ),
        const SizedBox(height: 55),
        // Login Button
      ElevatedButton(
  onPressed: _isLoading ? null : _login,
  style: ElevatedButton.styleFrom(
    backgroundColor: _isLoading ? Colors.grey[300] : null, // Optional: Change color when disabled
  ),
  child: _isLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF103783)),
          ),
        )
      : const Text(
          'Login',
          style: TextStyle(color: Color(0xFF103783)),
        ),
),
        const SizedBox(height: 15),
        // Forgot Password Button (unchanged)
         TextButton(
                  onPressed: () {
                    final TextEditingController emailController =
                        TextEditingController();
                    bool isLoading = false;
                    String message = '';

                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: const Text('Forgot Password?'),
                              contentPadding: const EdgeInsets.all(24.0),
                              content: SizedBox(
                                width: 400, // Increased width
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Please enter your registered email address. Instructions to reset your password will be sent to your inbox shortly.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    if (message.isNotEmpty)
                                      Text(
                                        message,
                                        style: TextStyle(
                                          color: message.contains("sent")
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    final email = emailController.text.trim();
                                    if (email.isEmpty) {
                                      setState(
                                          () => message = "Email is required.");
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                      message = '';
                                    });

                                    final result = await ApiService()
                                        .sendForgotPasswordEmail(email);

                                    setState(() {
                                      isLoading = false;
                                      message = result['success']
                                          ? "Password reset link sent successfully. Please check your email."
                                          : "Error: ${result['error']}";
                                    });
                                  },
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Send Reset Link'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close',
                                      style:
                                          TextStyle(color: Color(0xFF103783))),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF103783)),
                  ),
                ),
      ],
    ),
  ),
),
      ],
    );
  }
}
