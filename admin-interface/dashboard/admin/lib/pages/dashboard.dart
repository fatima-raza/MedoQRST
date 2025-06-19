import 'package:admin/pages/access_record.dart';
import 'package:admin/pages/add_ward.dart';
import 'package:admin/pages/admission_info.dart';
import 'package:admin/pages/available_beds.dart';
import 'package:admin/pages/bed_qr.dart';
import 'package:admin/pages/contact_info.dart';
import 'package:admin/pages/discharge_card.dart';
import 'package:admin/pages/login.dart';
import 'package:admin/pages/patient_identification.dart';
import 'package:admin/pages/patient_info.dart';
import 'package:admin/pages/staff_register.dart';
import 'package:admin/pages/change_password.dart';
import 'package:admin/pages/historyFile/history_file.dart';
import 'package:admin/services/network_client.dart';
import 'package:admin/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cookie_jar/cookie_jar.dart'; // Import CookieJar to handle cookies
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Global cookie management
final cookieJar = CookieJar();

class Dashboard extends StatefulWidget {
  final int loggedValue;

  const Dashboard({super.key, required this.loggedValue});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? selectedOption;
  String? selectedPatientID; // Track the selected option

  Map<String, dynamic>? selectedPatientData;

  // Build different body content based on the selected option
  Widget getBodyContent() {
    switch (selectedOption) {
      case '/available_beds':
        return AvailableBeds(
          onNext: (String route, bool fromBedPage) {
            setState(() {
              selectedOption = route;
              print(
                  "Navigating from AvailableBeds to PatientIdentification with fromBedPage: $fromBedPage");

              if (route == '/patient_identification') {
                selectedPatientData = {'fromBedPage': fromBedPage};
              }
            });
          },
        );

      case '/patient_identification':
        print("Selected Option Before Navigation: $selectedOption");
        bool fromBedPage = selectedPatientData?['fromBedPage'] ?? false;
        return PatientIdentification(
          fromBedPage: fromBedPage,
          onNext: (String route, Object? patientData) {
            setState(() {
              selectedOption = route;
              print(
                  'Navigating to: $selectedOption with PatientID: $selectedPatientID');

              if (patientData is Map<String, dynamic>) {
                selectedPatientData = patientData;
                selectedPatientID = selectedPatientData?['UserID'] ?? '';
              } else {
                selectedPatientData = null;
                selectedPatientID = '';
              }
              print("Patient Data received: $selectedPatientData");
              print("Updated PatientID: $selectedPatientID");
            });
          },
        );

      case '/patient_info':
        print("Navigating to PatientInfo with data: $selectedPatientData");
        bool isComingFromSidebar = selectedPatientData == null;
        bool isExistingPatient = selectedPatientData?['patientData'] !=
            null; // Check if patient exists
        bool isEditable = isComingFromSidebar ? false : true;
        print("isEditable set to: $isEditable");
        return PatientInfo(
          summaryData: selectedPatientData ?? {},
          isEditable: isEditable,
          onNext: (String route, Map<String, dynamic> data) {
            print("Navigating to: $route with arguments: $data");
            setState(() {
              selectedOption = route;
              selectedPatientData = data;
              print(
                  "Updated selectedPatientData in Dashboard: $selectedPatientData");
            });
          },
        );

      case '/admission_info':
        print("Navigating to AdmissionInfo with data: $selectedPatientData");
        bool isComingFromSidebar = selectedPatientData == null;
        bool isEditable = !isComingFromSidebar;
        print("isEditable set to: $isEditable");
        return AdmissionInfo(
          patientId: selectedPatientData?['patientId'] ?? '',
          isEditable: isEditable,
          onNext: (String route, Map<String, dynamic> data) {
            print("Navigating to: $route with arguments: $data");
            setState(() {
              selectedOption = route;
              selectedPatientData = data;
              print(
                  "Updated selectedPatientData in Dashboard: $selectedPatientData");
            });
          },
          onHomeRedirect: () {
            setState(() {
              selectedOption = ''; // triggers the default dashboard page
              selectedPatientData = null; // Clear any patient data
            });
          },
        );

      case '/contact_info':
        print("Navigating to ContactInfo with data: $selectedPatientData");
        bool isComingFromSidebar = selectedPatientData == null;
        bool isEditable = !isComingFromSidebar;
        print("isEditable set to: $isEditable");
        return ContactInfo(
          admissionNumber: selectedPatientData?['admissionNo'] ?? '',
          isEditable: isEditable,
          onNext: (String route, Map<String, dynamic> data) {
            print("Navigating to: $route with arguments: $data");
            setState(() {
              selectedOption = route;
              selectedPatientData = data;
            });
          },
        );

      case '/staff_register':
        return StaffRegister(
          onNext: () {
            setState(() {
              selectedOption =
                  '/staff_register'; // Update body to staff Register
            });
          },
        );
      case '/bed_qr':
        return AddBedScreen();
      case '/add_ward':
        return AddWard();
      case '/discharge_card':
        return DischargeCard();
      case '/access_record':
        return AccessRecordsScreen();
      case '/upload_cloud':
        return UploadToCloud();
      case '/change_password':
        return ChangePasswordScreen();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to MedoQRST Admin Dashboard!',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF103783),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your tasks and operations with ease.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }

  Future<String> getDefaultDocumentsDirectory() async {
    // Platform-specific logic
    if (Platform.isWindows) {
      return path.join(Platform.environment['USERPROFILE']!, 'Documents');
    } else if (Platform.isMacOS || Platform.isLinux) {
      return path.join(Platform.environment['HOME']!, 'Documents');
    } else {
      return '/storage/emulated/0/Documents'; // For Android if needed
    }
  }

  Future<void> selectDownloadLocation(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get saved path or default to Documents
    String defaultPath = await getDefaultDocumentsDirectory();
    String currentPath = prefs.getString('download_location') ?? defaultPath;

    // Ensure path is normalized
    currentPath = path.normalize(currentPath);

    TextEditingController pathController =
        TextEditingController(text: currentPath);

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Download Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'MedoQRST folder will be created in the selected location, along with its subfolders.'),
              const SizedBox(height: 16),
              TextField(
                controller: pathController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Download Location',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () async {
                      String? selected =
                          await FilePicker.platform.getDirectoryPath();
                      if (selected != null) {
                        pathController.text = path.normalize(selected);
                      }
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Set Location'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      String selectedDirectory = pathController.text;
      if (selectedDirectory.isEmpty) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const Center(child: CircularProgressIndicator()),
      );

      String medoFolderPath = path.join(selectedDirectory, 'MedoQRST');
      Directory medoFolder = Directory(medoFolderPath);
      if (!await medoFolder.exists()) {
        await medoFolder.create(recursive: true);
      }

      List<String> subFolders = [
        'Bed QR Codes',
        'Ward QR Codes',
        'History Files',
        'Discharge Summary',
      ];

      for (String folderName in subFolders) {
        Directory subFolder = Directory(path.join(medoFolderPath, folderName));
        if (!await subFolder.exists()) {
          await subFolder.create(recursive: true);
        }
      }

      await prefs.setString('download_location', medoFolderPath);

      Navigator.of(context).pop(); // Close progress dialog

      String formattedPath = path.normalize(medoFolderPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'MedoQRST folder set successfully at: $formattedPath',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.blueGrey[200],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'MedoQRST',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF103783),
      ),
      sideBar: SideBar(
        backgroundColor: Colors.white,
        textStyle: const TextStyle(
          color: Color.fromARGB(255, 122, 121, 121),
        ),
        selectedRoute: selectedOption ?? '',
        onSelected: (item) {
          setState(() {
            selectedOption = item.route ?? ''; // Update selected option
          });
        },
        header: GestureDetector(
          onTap: () {
            setState(() {
              selectedOption = null; // Reset to welcome page
            });
          },
          child: Container(
            height: 50,
            color: Colors.white,
            width: double.infinity,
            child: const Center(
              child: Text(
                'DASHBOARD',
                style: TextStyle(
                  color: Color.fromARGB(255, 122, 121, 121),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        footer: Container(
          height: 50,
          width: double.infinity,
          color: const Color.fromARGB(197, 255, 247, 247),
          child: Center(
            child: PopupMenuButton<String>(
              onSelected: (String value) async {
                if (value == 'download') {
                  await selectDownloadLocation(context);
                } else if (value == 'change_password') {
                  setState(() {
                    selectedOption = '/change_password';
                  });
                } else if (value == 'logout') {
                  // <<< Your Full Logout Functionality >>>
                  final baseCookies = await ApiService.cookieJar!
                      .loadForRequest(Uri.parse("http://localhost:8090"));
                  print("Cookies at base domain: $baseCookies");

                  final apiCookies = await ApiService.cookieJar!
                      .loadForRequest(Uri.parse("http://localhost:8090/api"));
                  print("Cookies at /api: $apiCookies");

                  final authCookies = await ApiService.cookieJar!
                      .loadForRequest(
                          Uri.parse("http://localhost:8090/api/auth/logout"));
                  print("Cookies at /api/auth/logout: $authCookies");

                  bool success = await ApiService.adminLogout();

                  if (success) {
                    print("Logging out...");
                    if (cookieJar != null) {
                      await cookieJar.deleteAll();
                      print("Cookies cleared. User logged out.");
                      final cookiesAfterLogout = await cookieJar.loadForRequest(
                          Uri.parse(
                              "${NetworkClient.cookieDomain}/api/auth/logout"));
                      print("Cookies after logout: $cookiesAfterLogout");
                    } else {
                      print(
                          "Error: cookieJar is null, unable to clear cookies.");
                    }

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Logout failed. Please try again.',
                          style: TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Colors.red.withOpacity(0.7),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Download Location'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Change Account Password'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.settings,
                    color: Color(0xFF103783),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Color(0xFF103783),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        items: [
          AdminMenuItem(
            title: 'Patient Registration',
            icon: Icons.app_registration,
            children: [
              AdminMenuItem(
                title: 'Available Beds',
                icon: Icons.event_available,
                route: '/available_beds',
              ),
              AdminMenuItem(
                title: 'Patient Identification',
                icon: Icons.person_search,
                route: '/patient_identification',
              ),
            ],
          ),
          AdminMenuItem(
            title: 'Bed QR Codes',
            icon: Icons.bed,
            route: '/bed_qr',
          ),
          AdminMenuItem(
            title: 'Ward QR Codes',
            icon: Icons.add_home_work,
            route: '/add_ward',
          ),
          AdminMenuItem(
            title: 'Staff Registration',
            icon: Icons.person,
            route: '/staff_register',
          ),
          AdminMenuItem(
            title: 'Discharge Summary',
            icon: Icons.print,
            route: '/discharge_card',
          ),
          AdminMenuItem(
            title: 'Cloud Upload',
            icon: Icons.cloud,
            route: '/upload_cloud',
          ),
          AdminMenuItem(
            title: 'Access Records',
            icon: Icons.file_copy,
            route: '/access_record',
          ),
        ],
      ),
      body: getBodyContent(),
    );
  }
}
