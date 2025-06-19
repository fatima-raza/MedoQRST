//history_file
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../services/google_drive_services.dart'; // Import your Drive services
import 'package:google_fonts/google_fonts.dart';
import '../../services/users_services.dart';
import 'file_sheets.dart';
import './pdfGeneration.dart';
import 'package:flutter/material.dart';
import '../../helper/downloadLocation.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class UploadToCloud extends StatefulWidget {
  final String? admissionNo; // Now nullable/optional
  final VoidCallback? onUploadComplete;  

  // Constructor with optional admissionNo
  const UploadToCloud({
    this.admissionNo,
    this.onUploadComplete,  // No 'required' keyword
    Key? key,
  }) : super(key: key);
  @override
  _UploadToCloudState createState() => _UploadToCloudState();
}

// _buildSheetCard function
Widget _buildSheetCard(String title, IconData icon, Map<String, dynamic> data,
    BuildContext context) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 4,
    color: Color(0xFFF5F5F5),
    child: InkWell(
      onTap: () {
        // Pass the context along with the title and data to show the popup
        showSheetPopup(context, title, data);
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Color.fromARGB(255, 122, 121, 121)),
              SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    ),
  );
}

class _UploadToCloudState extends State<UploadToCloud> {
  String? uploadedFileId;
  String? uploadedFileName;
  final FocusNode IDFocusNode = FocusNode();
  TextEditingController admissionIdController = TextEditingController();
  bool isLoading = false;
  String? noPatientFoundMessage; // Declare it as a class variable
  Map<String, dynamic>? userData;
  bool showFolder =
      true; // This manages whether to show the folder or the sheet cards
  bool isValidAdmissionID = true;
  String errorMessage = ''; // Error message string
  bool hasSearched = false;
  String noSheetFound = ''; // Error message string
  Map<String, dynamic> registrationSheetData =
      {}; // empty map, if not yet initialized
  Map<String, dynamic> consultationSheetData = {};
  Map<String, dynamic> progressReportData = {};
  Map<String, dynamic> dischargeSheetData = {};
  Map<String, dynamic> receivingNotes = {};
  Map<String, dynamic> prescriptionSheetData = {};
  Map<String, dynamic> drugSheetData = {};
  Map<String, dynamic> nextOfKinData = {};

  List<Map<String, String>> recentPdfs = [];
  bool hasPdfFiles = false; // Flag to check if PDFs are available
  OverlayEntry? _overlayEntry;
  bool _isHoveringSidebar = false;
  bool _isHoveringIcon = false;
  bool _isSidebarVisible = false;
  bool isSidebarVisible = false;
  // Define the pendingFiles list here
  List<String> pendingFiles = []; // Replace with your actual list of files
  String? historyFilesSubFolderPath;
  Future<int>? fileCountFuture;
//  bool isUploaded = false;

  @override
  void initState() {
    super.initState();
    fetchPendingFiles();
    fileCountFuture = countHistoryFiles();

    // NEW: Auto-search if admissionNo is provided
    if (widget.admissionNo != null) {
      // Set the admission ID in the controller
      admissionIdController.text = widget.admissionNo!;

      // Trigger the search after a small delay to allow widget to initialize
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSearch(widget.admissionNo!);
      });
    }
  }

  // NEW: Method to handle auto-search
  Future<void> _autoSearch(String admissionNo) async {
    setState(() {
      isLoading = true;
      userData = null;
      noPatientFoundMessage = null;
      hasSearched = true;
      showFolder = true;
    });

    try {
      final user = await UsersServices.getPatientDetails(admissionNo);
      if (user != null) {
        setState(() {
          userData = user;
        });
        await _fetchSheetData(admissionNo);
      } else {
        setState(() {
          noPatientFoundMessage = "No Patient Found For ID $admissionNo";
        });
      }
    } catch (e) {
      setState(() {
        noPatientFoundMessage = "Error searching: ${e.toString()}";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _uploadFile(String file) {
    // Your file upload logic here
    print('Uploading: $file');
  }

  Future<void> fetchPendingFiles() async {
    try {
      // Step 1: Get subfolder path
      String? subFolderPath = await getMedoSubFolderPath('History Files');

      if (subFolderPath == null) return;

      final dir = Directory(subFolderPath);

      if (await dir.exists()) {
        final List<FileSystemEntity> allFiles = dir.listSync();
        final RegExp filePattern = RegExp(r'^HF_\d{6}_P-\d{5}');

        // Step 2: Filter matching files
        final matchedFiles = allFiles
            .whereType<File>()
            .where((file) {
              final fileName = file.uri.pathSegments.last;
              return filePattern.hasMatch(fileName);
            })
            .map((file) => file.path)
            .toList();

        // Step 3: Update the list
        setState(() {
          pendingFiles = matchedFiles;
        });
      }
    } catch (e) {
      print('Error fetching pending files: $e');
    }
  }

// The modified function
  Future<int> countHistoryFiles() async {
    try {
      // Get the path to the 'History File' subfolder using the helper
      String? subFolderPath = await getMedoSubFolderPath('History Files');

      if (subFolderPath == null) return 0;

      // Store the subfolder path in the global variable
      historyFilesSubFolderPath = subFolderPath;

      final dir = Directory(subFolderPath);

      // Check if directory exists
      if (!await dir.exists()) return 0;

      // Define the RegExp pattern for matching files like HF-P-12345.pdf
      final pattern = RegExp(r'^HF_\d{6}_P-\d{5}', caseSensitive: false);

      // List and filter matching files
      final files = dir.listSync().where((entity) {
        return entity is File &&
            entity.path.toLowerCase().endsWith('.pdf') &&
            pattern.hasMatch(File(entity.path).uri.pathSegments.last);
      }).toList();

      return files.length;
    } catch (e) {
      print('Error counting history files: $e');
      return 0;
    }
  }

  // Method to manually update the file count
  void refreshFileCount() {
    setState(() {
      fileCountFuture =
          countHistoryFiles(); // Trigger a new Future to refresh count
    });
  }

  Future<void> fetchPatientData(String admissionID) async {
    if (admissionID.isEmpty) return;

    setState(() {
      isLoading = true;
      userData = null;
      noPatientFoundMessage = null;
      hasSearched = true; // Mark that a search has been performed
      showFolder = true; // Reset to folder view initially
    });

    // Call API to fetch patient details
    final user = await UsersServices.getPatientDetails(admissionID);
    print('🧾 Patient details fetched: $user');

    if (user != null) {
      setState(() {
        userData = user;
      });

      // Now fetch data for the sheets after patient is found
      await _fetchSheetData(admissionID);
    } else {
      setState(() {
        noPatientFoundMessage = "No Patient Found For ID $admissionID";
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchSheetDataForPatient(String admissionID) async {
    await _fetchSheetData(admissionID);
  }

// Function to fetch data for the sheets
  Future<void> _fetchSheetData(String admissionID) async {
    try {
      // Fetch all sheets data here
      final registrationSheet =
          await UsersServices.getRegistrationDetails(admissionID);
      final vitals = await UsersServices.getVitals(admissionID);
      final consultationSheet =
          await UsersServices.getConsultationSheet(admissionID);
      final prescriptionSheet = await UsersServices.getDrugDetails(admissionID);
      final progressReport = await UsersServices.getProgressReport(admissionID);
      final dischargeSheet =
          await UsersServices.getDischargeDetails(admissionID);
      final nextofkin = await UsersServices.getNextOfKinDetails(admissionID);
      final drugSheet = await UsersServices.getMedicationRecord(admissionID);

      // You can store the fetched data in respective variables or update the UI directly
      setState(() {
        // Assigning the fetched data to the respective variables
        registrationSheetData = registrationSheet ?? {};
        consultationSheetData = consultationSheet ?? {};
        prescriptionSheetData = prescriptionSheet ?? {};
        drugSheetData = drugSheet ?? {};

        progressReportData = progressReport ?? {};
        dischargeSheetData = dischargeSheet ?? {};
        receivingNotes = vitals ?? {};
        nextOfKinData = nextofkin ?? {};
      });

      // print("Stored in progresReportData: $progressReportData");
    } catch (e) {
      // Handle errors if the API calls fail
      setState(() {
        noSheetFound = "Error fetching sheet data: $e";
      });
    }
  }

  Future<void> openPdf() async {
    if (uploadedFileId == null || uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("No uploaded file available to open!",
                style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.blueGrey[200]),
      );
      return;
    }

    String? filePath = await GoogleDriveService()
        .openPdfFromDrive(uploadedFileId!, uploadedFileName!);

    if (filePath != null) {
      OpenFile.open(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("❌ Failed to open PDF!",
                style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.red.withOpacity(0.7)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> selectedRegistrationFields = {
      'Admission_no': registrationSheetData['Admission_no'],
      'Admission_date': registrationSheetData['Admission_date'],
      'Admission_time': registrationSheetData['Admission_time'],
      'Receiving_note': registrationSheetData['Receiving_note'],
      'Primary_diagnosis': registrationSheetData['Primary_diagnosis'],
      'Associate_diagnosis': registrationSheetData['Associate_diagnosis'],
      'Ward_no': registrationSheetData['Ward_no'],
      'Bed_no': registrationSheetData['Bed_no'],
      'doctor': registrationSheetData['DoctorName'],
      'Disposal_status': registrationSheetData['Disposal_status']
    };
    final disposalStatus = userData?['Disposal_status'];
    final uploadedToCloud = userData?['Uploaded_to_cloud'];
    final isUploaded = uploadedToCloud == true;

    // print('📄 Discharge Sheet Data being passed:');
    print('🗂 Registration: $selectedRegistrationFields');
    // print('🏥 Discharge Data: $dischargeSheetData');
    // print('👨‍⚕ User Data: $userData')

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'Upload History Files',
            style: GoogleFonts.roboto(
              color: const Color.fromARGB(255, 122, 121, 121),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: TextField(
                        controller: admissionIdController,
                        focusNode: IDFocusNode,
                        decoration: InputDecoration(
                          labelText: "Enter Patient Admission No",
                          labelStyle: GoogleFonts.roboto(
                            color: IDFocusNode.hasFocus
                                ? Color.fromARGB(255, 122, 121, 121)
                                : Colors.grey,
                          ),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isValidAdmissionID
                                  ? Colors.blue.shade900
                                  : Colors.red,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isValidAdmissionID
                                  ? Color.fromARGB(255, 122, 121, 121)
                                  : Colors.red,
                              width: 1,
                            ),
                          ),
                          suffixIcon: Tooltip(
                            message: "Fetch Details",
                            child: IconButton(
                              icon: Icon(Icons.search),
                              onPressed: () {
                                String admissionID =
                                    admissionIdController.text.trim();
                                setState(() {
                                  userData = null;
                                  isValidAdmissionID = true;
                                  errorMessage = '';
                                });

                                if (admissionID.isEmpty) {
                                  setState(() {
                                    isValidAdmissionID = false;
                                    errorMessage = 'Admission ID is required';
                                  });
                                } else {
                                  setState(() {
                                    isValidAdmissionID = true;
                                    errorMessage = '';
                                  });
                                  fetchPatientData(admissionID);
                                }
                              },
                            ),
                          ),
                          errorText: isValidAdmissionID ? null : errorMessage,
                        ),
                        cursorColor: Color.fromARGB(255, 122, 121, 121),
                        onSubmitted: (value) {
                          String admissionID = value.trim();
                          setState(() {
                            userData = null;
                            isValidAdmissionID = true;
                            errorMessage = '';
                          });

                          if (admissionID.isEmpty) {
                            setState(() {
                              isValidAdmissionID = false;
                              errorMessage = 'Admission ID is required';
                            });
                          } else {
                            setState(() {
                              isValidAdmissionID = true;
                              errorMessage = '';
                            });
                            fetchPatientData(admissionID);
                          }
                        },
                      ),
                    ),
                  ),

                   // Horizontal divider
    const Divider(
      height: 24,
      thickness: 1,
      // color: Colors.grey.shade300,
      indent: 16,
      endIndent: 16,
    ),
                  SizedBox(height: 20),
                  if (!hasSearched) ...[
                    
                    // SizedBox(
                    //   height: MediaQuery.of(context).size.height * 0.6,
                    //   child: Center(
                    //     child: Text(
                    //       "No File to display",
                    //       style:
                    //           TextStyle(fontSize: 18, color: Colors.grey[600]),
                    //     ),
                    //   ),
                    // ),
                  ] else if (noPatientFoundMessage != null) ...[
                    Center(
                      child: Text(
                        noPatientFoundMessage!,
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ),
                  ] else if (userData != null) ...[
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "History File Found",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF103783),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          if (!showFolder)
                            IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: Colors.grey[600]),
                              onPressed: () {
                                setState(() {
                                  showFolder = true;
                                });
                              },
                            ),
                          Expanded(
                            child: Center(
                              child: Text(
                                "Patient Name: ${userData!['Name']} | Admission No: ${registrationSheetData!['Admission_no']} | Patient ID: ${userData!['UserID']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    if (showFolder)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.grey.withOpacity(0.2),
                            onTap: () {
                              setState(() {
                                showFolder = false;
                              });
                            },
                            child: ListTile(
                              tileColor: Colors.blueGrey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.folder,
                                  color: Colors.white,
                                  size: 28.0,
                                ),
                              ),
                              title: Text(
                                "HF_${registrationSheetData!['Admission_no']}_${userData!['UserID']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                "Click to view details",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14.0,
                                ),
                              ),
                              // bool isUploaded = false;  // Add this to your state

// Inside your build method:
// Conditionally render the icon or null
                              trailing: disposalStatus == null
                                  ? null
                                  : MouseRegion(
                                      child: IconButton(
                                        icon: Icon(
                                          isUploaded
                                              ? Icons.cloud_done
                                              : Icons.cloud_upload,
                                          color: isUploaded
                                              ? Colors.green
                                              : const Color(0xFF103783),
                                        ),
                                        onPressed: () async {
                                          if (!isUploaded) {
                                            try {
                                              final pdfGenerator = PdfGenerator(
                                                  historyFilesSubFolderPath!);
                                              bool uploadSuccess =
                                                  await pdfGenerator
                                                      .generatePdf(
                                                userData!,
                                                registrationSheetData,
                                                nextOfKinData,
                                                consultationSheetData,
                                                prescriptionSheetData,
                                                progressReportData,
                                                dischargeSheetData,
                                                receivingNotes,
                                                drugSheetData,
                                              );

                                              if (uploadSuccess) {
                                                setState(() {
                                                  userData![
                                                          'Uploaded_to_cloud'] =
                                                      true;
                                                });

                                                  // Call the callback if it exists
                                                   if (widget.onUploadComplete != null) {
                                                       widget.onUploadComplete!();
                                                                       }
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Uploaded to Cloud Successfully',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black)),
                                                    backgroundColor:
                                                        Colors.blueGrey[200],
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Upload Failed',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black)),
                                                    backgroundColor: Colors.red
                                                        .withOpacity(0.7),
                                                    duration:
                                                        Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            } catch (e, stackTrace) {
                                              print('Upload Error: $e');
                                              print('Stack Trace: $stackTrace');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Upload Failed: $e',
                                                      style: TextStyle(
                                                          color: Colors.black)),
                                                  backgroundColor: Colors.red
                                                      .withOpacity(0.7),
                                                  duration:
                                                      Duration(seconds: 3),
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Already uploaded to cloud',
                                                    style: TextStyle(
                                                        color: Colors.black)),
                                                backgroundColor: Colors.green
                                                    .withOpacity(0.7),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        tooltip: isUploaded
                                            ? 'Already Uploaded'
                                            : 'Upload to Cloud',
                                      ),
                                    ),

                         
                            ),
                          ),
                        ),
                      ),
                    if (!showFolder)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.8,
                              ),
                              itemCount: 7,
                              itemBuilder: (context, index) {
                                final List<Map<String, dynamic>> sheetData = [
                                  {
                                    "title": "Registration Sheet",
                                    "icon": Icons.assignment_ind,
                                    "data": {
                                      "registration": registrationSheetData,
                                      "user": userData,
                                      "nextofkin": nextOfKinData,
                                    }
                                  },
                                  {
                                    "title": "Receiving Notes",
                                    "icon": Icons.receipt_long,
                                    "data": {
                                      "registration":
                                          selectedRegistrationFields,
                                      "vitals": receivingNotes,
                                    }
                                  },
                                  {
                                    "title": "Prescription Sheet",
                                    "icon": Icons.local_pharmacy,
                                    "data": prescriptionSheetData,
                                  },
                                  {
                                    "title": "Drug Sheet",
                                    "icon": Icons.medication,
                                    "data": drugSheetData,
                                  },
                                  {
                                    "title": "Progress Report",
                                    "icon": Icons.bar_chart,
                                    "data": {
                                      ...progressReportData,
                                      "Name": userData!['Name'],
                                      "UserID": userData!['UserID'],
                                      "Admission_no": registrationSheetData![
                                          'Admission_no'],
                                    },
                                  },
                                  {
                                    "title": "Consultation Sheet",
                                    "icon": Icons.forum,
                                    "data": consultationSheetData,
                                  },
                                  {
                                    "title": "Discharge Sheet",
                                    "icon": Icons.exit_to_app,
                                    "data": {
                                      "registration":
                                          selectedRegistrationFields,
                                      "discharge": dischargeSheetData,
                                      "userData": userData,
                                    }
                                  },
                                ];

                                return _buildSheetCard(
                                  sheetData[index]['title'],
                                  sheetData[index]['icon'],
                                  sheetData[index]['data'],
                                  context,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
