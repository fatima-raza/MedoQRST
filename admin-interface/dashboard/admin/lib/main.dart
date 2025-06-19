import 'package:flutter/material.dart';
import 'package:admin/pages/login.dart';
import 'package:admin/pages/dashboard.dart';
import 'package:admin/services/network_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Global key for navigation (for navigation from anywhere in the app)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter bindings are initialized before checking session
  WidgetsFlutterBinding.ensureInitialized();

  print("Initializing app...");

  // Initialize cookie jar with persistence
  final appDocDir = await getApplicationDocumentsDirectory();
  final cookiePath = path.join(appDocDir.path, 'cookies');
  await NetworkClient.initializeCookies(cookiePath);

  NetworkClient.setupInterceptors(_navigateToLogin);

  print("Checking session...");
  bool isLoggedIn = await NetworkClient.checkSession();
  print("Is logged in: $isLoggedIn");

  // If not logged in, redirect to the login screen
  if (!isLoggedIn) {
    await NetworkClient.clearCookies(); // Clear cookies if not logged in
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// Function to navigate to the login screen (clear cookies and reset state)
void _navigateToLogin() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  });
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorKey: navigatorKey, // Pass the navigatorKey to handle navigation
      // Define the initial route based on login status
      initialRoute: isLoggedIn
          ? '/dashboard'
          : '/', // If logged in, go to dashboard, else login
      routes: {
        '/': (context) => const LoginScreen(), // Login screen
        '/dashboard': (context) =>
            Dashboard(loggedValue: 1), // Replace with your dashboard screen
      },
    );
  }
}
