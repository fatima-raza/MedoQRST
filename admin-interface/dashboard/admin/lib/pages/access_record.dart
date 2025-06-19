import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/google_drive_services.dart';
import 'dart:io';
import '../helper/downloadLocation.dart';
import 'recentPdfs.dart';
import 'patient_identification.dart';
import '../services/api_service.dart';

class AccessRecordsScreen extends StatefulWidget {
  @override
  _AccessRecordsScreenState createState() => _AccessRecordsScreenState();
}

class _AccessRecordsScreenState extends State<AccessRecordsScreen> {
  String selectedDateOption =
      "Uploaded Today"; // Stores the selected date option
  bool isMenuOpen = false;
  String searchQuery = "";
  // Variable to track selected filter
  String selectedFilter = "Filter by Patient ID";
  final ScrollController _scrollController = ScrollController();

  Future<List<drive.File>>? searchResults;
  final GoogleDriveService driveService = GoogleDriveService();
  final FocusNode IDFocusNode = FocusNode();
  TextEditingController patientIdController = TextEditingController();
  // List to hold the fetched files
  List<String> fileList = [];
  bool isLoading = false;
  String bodyHeading = "No files selected yet";
  bool isViewingCloudFiles = false;
  List<String> recentPdfs = [];
  String? historyFilesDirectoryPath;
  String heading = '';
  bool _showValidationError = false;
  final RegExp _patientIdRegex = RegExp(r'^P-\d{5}$');
  final ApiService _apiService = ApiService();
  String? _fetchedPatientId;

  @override
  void initState() {
    super.initState();
    selectedFilter = "Filter by Patient ID";
    //  heading = 'Recent Downloads'; // Ensure it's set when the page loads
    setHistoryFilesDirectoryPath();
    print("📂 History Files Directory Path: $historyFilesDirectoryPath");
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              isViewingCloudFiles = false;
              searchQuery = "";
              searchResults = Future.value([]);
              patientIdController.clear();
              _showValidationError = false;
            });
          },
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 122, 121, 121)),
          label: Text(
            "Back to Downloads",
            style: GoogleFonts.roboto(
              color: const Color.fromARGB(255, 122, 121, 121),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

 String _getResultHeading(int fileCount) {
// Case when no files exist

  // Handle different filters
  switch (selectedFilter) {
    case "Filter by Patient ID":
      return fileCount == 1 
          ? "History File Found for Patient ID ${patientIdController.text.trim()}"
          : "History Files Found for Patient ID ${patientIdController.text.trim()}";
    
    case "Filter by Date":
      if (selectedDateOption.contains("Today")) {
        return fileCount == 1 
            ? "History File Uploaded Today" 
            : "History Files Uploaded Today";
      } else if (selectedDateOption.contains("Yesterday")) {
        return fileCount == 1 
            ? "History File Uploaded Yesterday" 
            : "History Files Uploaded Yesterday";
      } else {
        final date = selectedDateOption.replaceAll(" (selected date)", "");
        return fileCount == 1 
            ? "History File Uploaded on $date" 
            : "History Files Uploaded on $date";
      }
    
    case "List All Records":
      return fileCount == 1 
          ? "History File Found" 
          : "History Files Found";
    
    default:
      return "Search Results";
  }
}

 

void _handleSelection(String filter) {
  setState(() {
    _showValidationError = false;
    selectedFilter = filter;
    isViewingCloudFiles = false; // Reset to show local files when filter changes
    searchResults = Future.value([]);
    searchQuery = "";
    selectedDateOption = "";

    if (filter != "Filter by Patient ID") {
      patientIdController.clear();
    }
  });

  if (filter == "List All Records") {
    // Don't fetch automatically - wait for explicit button click
  }
}

  void _validateAndSearch() {
    setState(() => _showValidationError = true);
    if (_validatePatientId(patientIdController.text) == null) {
      _searchFile();
    }
  }

  void _showCnicSearchDialog(BuildContext context) {
    final cnicController = TextEditingController();
    final cnicFocusNode = FocusNode();
    bool showValidationError = false;
    bool isLoading = false;
    bool searchCompleted = false;
    String? fetchedPatientId;

    // Define colors
    const deepBlue = Color(0xFF103783); // Deep blue color
    const greyColor = Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String? validateCnic(String? value) {
              if (value == null || value.isEmpty) return 'Please enter CNIC';
              final cleanCnic = value.replaceAll('-', '');
              if (cleanCnic.length != 13)
                return 'CNIC must contain exactly 13 digits';
              if (!RegExp(r'^[0-9]{13}$').hasMatch(cleanCnic))
                return 'CNIC must contain only numbers';
              if (value.contains('-') &&
                  !RegExp(r'^[0-9]{5}-[0-9]{7}-[0-9]{1}$').hasMatch(value)) {
                return 'Format must be XXXXX-XXXXXXX-X';
              }
              return null;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                "Get Patient ID Using CNIC",
                style: TextStyle(
                  color: deepBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!searchCompleted)
                    TextField(
                      controller: cnicController,
                      focusNode: cnicFocusNode,
                      cursorColor: greyColor,
                      decoration: InputDecoration(
                        labelText: "Enter CNIC",
                        labelStyle: TextStyle(color: greyColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: greyColor, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: greyColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: showValidationError
                            ? validateCnic(cnicController.text)
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black87),
                    ),
                  if (searchCompleted && fetchedPatientId != null)
                    Column(
                      children: [
                        Icon(Icons.check_circle, color: deepBlue, size: 48),
                        SizedBox(height: 16),
                        Text(
                          "Patient Found!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Patient ID: $fetchedPatientId",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                if (!searchCompleted)
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: greyColor),
                    ),
                  ),
                if (!searchCompleted)
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => showValidationError = true);

                            if (validateCnic(cnicController.text) == null) {
                              setState(() => isLoading = true);
                              try {
                                final cleanCnic = cnicController.text
                                    .replaceAll('-', '')
                                    .trim();
                                final result = await _apiService
                                    .checkExistingPatient(cleanCnic);

                                if (result != null && result['found'] == true) {
                                  setState(() {
                                    fetchedPatientId =
                                        result['data']['UserID']?.toString();
                                    searchCompleted = true;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result?['message'] ??
                                            'Patient not found')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Search error: ${e.toString()}')),
                                );
                              } finally {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Search",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                if (searchCompleted)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, fetchedPatientId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoResultsMessage() {
    String message;

    switch (selectedFilter) {
      case "Filter by Patient ID":
        message = "No Records found for the entered Patient ID";
        break;
      case "Filter by Date":
        if (selectedDateOption.contains("Today")) {
          message = "No Files Uploaded Today";
        } else if (selectedDateOption.contains("Yesterday")) {
          message = "No Files Uploaded Yesterday";
        } else {
          final date = selectedDateOption.replaceAll(" (selected date)", "");
          message = "No Files Uploaded on $date";
        }
        break;
      case "List All Records":
        message = "No Files to List";
        break;
      default:
        message = "No Files Found";
    }

    return Center(
      child: Text(
        message,
        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
      ),
    );
  }

  void openPdfInBrowser(String fileId) async {
    final url = 'https://drive.google.com/file/d/$fileId/view';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("❌ Could not launch $url");
    }
  }

//function to open pdf uploaded in drive

  void handleOpenPdf(String fileId, String fileName) async {
    String? filePath = await driveService.openPdfFromDrive(fileId, fileName);
    if (filePath != null) {
      OpenFile.open(filePath); // Open the file using a PDF viewer
    } else {
      print("Failed to open PDF");
    }
  }

  Future<void> setHistoryFilesDirectoryPath() async {
    final path = await getMedoSubFolderPath('History Files');
    print('Path: $path');

    if (path == null) {
      print("❌ Error: Unable to access selected Downloads folder!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to access selected Downloads folder.",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.red.withOpacity(0.7),
        ),
      );
    } else {
      setState(() {
        historyFilesDirectoryPath = path;
      });
      print('✅ Updated historyFilesDirectoryPath: $historyFilesDirectoryPath');
    }
  }

  Future<void> _searchFile() async {
    final validationError = _validatePatientId(searchQuery);
    if (validationError != null) {
      setState(() {}); // Show error UI
      return; // Exit if invalid
    }

    setState(() {
      isViewingCloudFiles = true;
      searchResults = driveService.searchFile(searchQuery);
    });
  }



  String buildDynamicHeading(AsyncSnapshot<List<drive.File>> snapshot) {
  if (!isViewingCloudFiles) return "Recent Downloads";
  
  final fileCount = snapshot.data?.length ?? 0;
  return _getResultHeading(fileCount);
}

  // void handleDownload(String fileId, String fileName) async {
  //   Uint8List? fileData =
  //       await driveService.downloadFileFromDrive(fileId, fileName);

  //   if (fileData != null) {
  //     // Handle file saving using file picker or any desired logic
  //     final String? path = await FilePicker.platform.saveFile(
  //       dialogTitle: "Save PDF",
  //       fileName: fileName,
  //     );

  //     if (path != null) {
  //       File file = File(path);
  //       await file.writeAsBytes(fileData);
  //       print("File saved successfully at $path");
  //     } else {
  //       print("User canceled file saving.");
  //     }
  //   } else {
  //     print("Failed to download file.");
  //   }
  // }

  Future<void> handleDownload(String fileId, String fileName) async {
  try {
    Uint8List? fileData = await driveService.downloadFileFromDrive(fileId, fileName);
    
    if (fileData == null) {
      throw Exception("Failed to download file data");
    }

    // Get the directory path
    final directoryPath = await getMedoSubFolderPath('History Files');
    if (directoryPath == null) {
      throw Exception("Could not access History Files directory");
    }

    // Create directory if it doesn't exist
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Create file path and save
    final filePath = '$directoryPath/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(fileData);

    // Show snackbar with open option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DefaultTextStyle(
          style: const TextStyle(color: Colors.black),
          child: Text('File saved to History Files folder'),
        ),
        backgroundColor: Colors.blueGrey.shade200,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.black,
          onPressed: () async {
            try {
              await OpenFile.open(filePath);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open file: ${e.toString()}')),
              );
            }
          },
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}
  String? _validatePatientId(String? value) {
    if (!_showValidationError) return null;

    if (value == null || value.isEmpty) {
      return 'Patient ID is required';
    }
    if (!_patientIdRegex.hasMatch(value)) {
      return 'Invalid format (P-xxxxx where x are digits)';
    }
    return null;
  }


  void _fetchAllRecords() {
    setState(() {
      isViewingCloudFiles = true;
      searchResults = driveService.listAllFiles();
    });
  }



  void _fetchFilesByDate(DateTime date) async {
    setState(() {
      isViewingCloudFiles = true;
      isLoading = true;
      searchResults = Future.value([]);
    });

    setState(() {
      searchResults = driveService.getFilesByDate(date);
      isLoading = false;
    });
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final localTime = dateTime.toLocal(); // Convert to local time
    final formatter =
        DateFormat('dd-MM-yyyy | hh:mm a'); // 12-hour format with AM/PM
    return formatter.format(localTime);
  }

  // void _selectDateFromCalendar() async {
  //   DateTime? selectedDate = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2100),
  //   );

  //   if (selectedDate != null) {
  //     setState(() {
  //       selectedDateOption =
  //           "${DateFormat('dd-MM-yyyy').format(selectedDate)} (selected date)"; // ✅ Append (selected date)
  //     });
  //     _fetchFilesByDate(selectedDate);
  //   }
  // }

  void _selectDateFromCalendar() async {
  DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade900,       // Header background (deep blue)
            onPrimary: Colors.white,             // Header text color
            surface: Colors.white,               // Calendar background
            onSurface: Colors.black,            // Calendar text
          ),
          dialogBackgroundColor: Colors.white,  // Dialog background
        ),
        child: child!,
      );
    },
  );

  if (selectedDate != null) {
    setState(() {
      selectedDateOption = 
          "${DateFormat('dd-MM-yyyy').format(selectedDate)} (selected date)";
    });
    _fetchFilesByDate(selectedDate);
  }
}


Widget _buildFilterWidget() {
  // Reusable back button widget (only for List All filter)
  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              if (isViewingCloudFiles) {
                // Currently viewing cloud files - go back to downloads
                isViewingCloudFiles = false;
                searchQuery = "";
                searchResults = Future.value([]);
                patientIdController.clear();
                _showValidationError = false;
              } else {
                // Currently viewing local files - list all records
                isViewingCloudFiles = true;
                _fetchAllRecords();
              }
            });
          },
          icon: Icon(
            isViewingCloudFiles ? Icons.arrow_back : Icons.list,
            color: const Color.fromARGB(255, 122, 121, 121),
          ),
          label: Text(
            isViewingCloudFiles ? "Back to Downloads" : "List All Records",
            style: GoogleFonts.roboto(
              color: const Color.fromARGB(255, 122, 121, 121),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // Filter by Patient ID
  if (selectedFilter == "Filter by Patient ID") {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: TextField(
                controller: patientIdController,
                focusNode: IDFocusNode,
                decoration: InputDecoration(
                  labelText: "Enter Patient ID",
                  labelStyle: GoogleFonts.roboto(
                    color: IDFocusNode.hasFocus
                        ? Colors.blueGrey[100]
                        : Colors.grey,
                  ),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _showValidationError &&
                              _validatePatientId(patientIdController.text) !=
                                  null
                          ? Colors.red
                          : Colors.grey,
                      width: 1,
                    ),
                  ),
                  errorText: _validatePatientId(patientIdController.text),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _validateAndSearch,
                  ),
                ),
                onChanged: (value) => searchQuery = value,
                onSubmitted: (_) => _validateAndSearch(),
              ),
            ),
          ),
        ),
        if (!isViewingCloudFiles)
          TextButton(
            onPressed: () {
              _showCnicSearchDialog(context);
            },
            child: Text(
              "Get Patient ID using CNIC",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        if (isViewingCloudFiles) 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    isViewingCloudFiles = false;
                    searchQuery = "";
                    searchResults = Future.value([]);
                    patientIdController.clear();
                    _showValidationError = false;
                  });
                },
                icon: const Icon(Icons.arrow_back,
                    color: Color.fromARGB(255, 122, 121, 121)),
                label: Text(
                  "Back to Downloads",
                  style: GoogleFonts.roboto(
                    color: const Color.fromARGB(255, 122, 121, 121),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        _buildDivider(),
      ],
    );
  }

  // Filter by Date
  else if (selectedFilter == "Filter by Date") {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
 Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Container(
      width: 600, // Constrains the width to 300 pixels
      child: DropdownButtonFormField<String>(
        value: selectedDateOption.isEmpty ? null : selectedDateOption,
        decoration: InputDecoration(
          hintText: "Select Date",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade800,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        items: [
          DropdownMenuItem(
            value: "Uploaded Today",
            child: Text("Uploaded Today"),
          ),
          DropdownMenuItem(
            value: "Uploaded Yesterday",
            child: Text("Uploaded Yesterday"),
          ),
          DropdownMenuItem(
            value: "Use Calendar",
            child: Text("Select Custom Date"),
          ),
          if (selectedDateOption.isNotEmpty &&
              !["Uploaded Today", "Uploaded Yesterday", "Use Calendar"]
                  .contains(selectedDateOption))
            DropdownMenuItem(
              value: selectedDateOption,
              child: Text(selectedDateOption),
            ),
        ],
        onChanged: (value) {
          if (value == "Use Calendar") {
            _selectDateFromCalendar();
          } else {
            setState(() {
              selectedDateOption = value!;
              isViewingCloudFiles = true; // Show cloud files when date selected
              if (value == "Uploaded Today") {
                _fetchFilesByDate(DateTime.now());
              } else if (value == "Uploaded Yesterday") {
                _fetchFilesByDate(DateTime.now().subtract(Duration(days: 1)));
              }
            });
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return [
            Text("Uploaded Today", style: TextStyle(color: Colors.black)),
            Text("Uploaded Yesterday", style: TextStyle(color: Colors.black)),
            Text("Select Custom Date", style: TextStyle(color: Colors.black)),
            if (selectedDateOption.isNotEmpty &&
                !["Uploaded Today", "Uploaded Yesterday", "Use Calendar"]
                    .contains(selectedDateOption))
              Text(selectedDateOption, style: TextStyle(color: Colors.black)),
          ];
        },
      ),
    ),
  ),
),
        if (isViewingCloudFiles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    isViewingCloudFiles = false;
                    searchQuery = "";
                    searchResults = Future.value([]);
                    patientIdController.clear();
                    _showValidationError = false;
                  });
                },
                icon: const Icon(Icons.arrow_back,
                    color: Color.fromARGB(255, 122, 121, 121)),
                label: Text(
                  "Back to Downloads",
                  style: GoogleFonts.roboto(
                    color: const Color.fromARGB(255, 122, 121, 121),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        _buildDivider(),
      ],
    );
  }

  // List All Records - Only this filter gets the toggle button
  else if (selectedFilter == "List All Records") {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton(),
        _buildDivider(),
      ],
    );
  }

  // Default case
  return SizedBox.shrink();
}
  // Widget _buildFilterWidget() {
  //   // Reusable back button widget
  //   Widget _buildBackButton() {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //       child: Align(
  //         alignment: Alignment.centerLeft,
  //         child: TextButton.icon(
  //           onPressed: () {
  //             setState(() {
  //               isViewingCloudFiles = false;
  //               searchQuery = "";
  //               searchResults = Future.value([]);
  //               patientIdController.clear();
  //               _showValidationError = false;
  //             });
  //           },
  //           icon: const Icon(Icons.arrow_back,
  //               color: Color.fromARGB(255, 122, 121, 121)),
  //           label: Text(
  //             "Back to Downloads",
  //             style: GoogleFonts.roboto(
  //               color: const Color.fromARGB(255, 122, 121, 121),
  //               fontSize: 16,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   // Filter by Patient ID
  //   if (selectedFilter == "Filter by Patient ID") {
  //     return Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 10),
  //           child: Center(
  //             child: ConstrainedBox(
  //               constraints: BoxConstraints(maxWidth: 600),
  //               child: TextField(
  //                 controller: patientIdController,
  //                 focusNode: IDFocusNode,
  //                 decoration: InputDecoration(
  //                   labelText: "Enter Patient ID",
  //                   labelStyle: GoogleFonts.roboto(
  //                     color: IDFocusNode.hasFocus
  //                         ? Colors.blueGrey[100]
  //                         : Colors.grey,
  //                   ),
  //                   border: OutlineInputBorder(),
  //                   focusedBorder: OutlineInputBorder(
  //                     borderSide: BorderSide(color: Colors.grey, width: 2),
  //                   ),
  //                   enabledBorder: OutlineInputBorder(
  //                     borderSide: BorderSide(
  //                       color: _showValidationError &&
  //                               _validatePatientId(patientIdController.text) !=
  //                                   null
  //                           ? Colors.red
  //                           : Colors.grey,
  //                       width: 1,
  //                     ),
  //                   ),
  //                   errorText: _validatePatientId(patientIdController.text),
  //                   suffixIcon: IconButton(
  //                     icon: Icon(Icons.search),
  //                     onPressed: _validateAndSearch,
  //                   ),
  //                 ),
  //                 onChanged: (value) => searchQuery = value,
  //                 onSubmitted: (_) => _validateAndSearch(),
  //               ),
  //             ),
  //           ),
  //         ),
  //         if (!isViewingCloudFiles)
  //           TextButton(
  //             onPressed: () {
  //               _showCnicSearchDialog(context);
  //             },
  //             child: Text(
  //               "Get Patient ID using CNIC",
  //               style: TextStyle(color: Colors.grey),
  //             ),
  //           ),
  //         if (isViewingCloudFiles) _buildBackButton(),
  //         _buildDivider(),
  //       ],
  //     );
  //   }

  //   // Filter by Date
  //   else if (selectedFilter == "Filter by Date") {
  //     return Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //           child: DropdownButtonFormField<String>(
  //             value: selectedDateOption.isEmpty ? null : selectedDateOption,
  //             decoration: InputDecoration(
  //               hintText: "Select Date",
  //               border: OutlineInputBorder(),
  //               contentPadding:
  //                   EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  //             ),
  //             items: [
  //               DropdownMenuItem(
  //                   value: "Uploaded Today", child: Text("Uploaded Today")),
  //               DropdownMenuItem(
  //                   value: "Uploaded Yesterday",
  //                   child: Text("Uploaded Yesterday")),
  //               DropdownMenuItem(
  //                   value: "Use Calendar", child: Text("Use Calendar")),
  //               if (selectedDateOption.isNotEmpty &&
  //                   selectedDateOption != "Uploaded Today" &&
  //                   selectedDateOption != "Uploaded Yesterday" &&
  //                   selectedDateOption != "Use Calendar")
  //                 DropdownMenuItem(
  //                   value: selectedDateOption,
  //                   child: Text(selectedDateOption),
  //                 ),
  //             ],
  //             selectedItemBuilder: (BuildContext context) {
  //               return [
  //                 Text("Uploaded Today"),
  //                 Text("Uploaded Yesterday"),
  //                 Text("Use Calendar"),
  //                 if (selectedDateOption.isNotEmpty &&
  //                     selectedDateOption != "Uploaded Today" &&
  //                     selectedDateOption != "Uploaded Yesterday" &&
  //                     selectedDateOption != "Use Calendar")
  //                   Text(selectedDateOption,
  //                       style: TextStyle(color: Colors.black)),
  //               ];
  //             },
  //             onChanged: (value) {
  //               if (value == "Use Calendar") {
  //                 _selectDateFromCalendar();
  //               } else {
  //                 setState(() {
  //                   selectedDateOption = value!;
  //                   if (value == "Uploaded Today") {
  //                     _fetchFilesByDate(DateTime.now());
  //                   } else if (value == "Uploaded Yesterday") {
  //                     _fetchFilesByDate(
  //                         DateTime.now().subtract(Duration(days: 1)));
  //                   }
  //                 });
  //               }
  //             },
  //           ),
  //         ),
  //         if (isViewingCloudFiles) _buildBackButton(),
  //         _buildDivider(),
  //       ],
  //     );
  //   }

   

  //   // Default case
  //   return SizedBox.shrink();
  // }

  @override
  Widget build(BuildContext context) {
    print("🏗 Building with isViewingCloudFiles: $isViewingCloudFiles");
    return Scaffold(
        body: Stack(
      children: [
        // Main Content
        Column(
          children: [
            // AppBar
            AppBar(
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              title: Text(
                'Access Records',
                style: GoogleFonts.roboto(
                  color: const Color.fromARGB(255, 122, 121, 121),
                ),
              ),
              centerTitle: true,
            ),

            // Search Field for suppoerting different search options

            _buildFilterWidget(),

            Expanded(
              child: isViewingCloudFiles
                  ? FutureBuilder<List<drive.File>>(
                      future: searchResults,
                      builder: (context, snapshot) {
                        // Loading state
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center( child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ));
                        }

                        // Error state
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error fetching files.",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                          );
                        }
final files = snapshot.data ?? [];
final heading = buildDynamicHeading(snapshot);

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (heading.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Text(
          heading,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: files.isEmpty ? Colors.grey : Colors.grey.shade700,
            letterSpacing: 0.75,
          ),
        ),
      ),

    if (files.isEmpty)
      Expanded(child: Center(child: Text("No Records Found")))
                            else
                              Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsets.all(8),
                                  itemCount: files.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(),
                                  itemBuilder: (context, index) {
                                    final file = files[index];
                                    final fileName =
                                        file.name ?? "Unknown File";
                                    final createdTime = file.createdTime != null
                                        ? formatDateTime(file.createdTime!)
                                        : "Unknown Date";

                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 3,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        leading: Icon(Icons.picture_as_pdf,
                                            color: const Color(0xFF103783),
                                            size: 32),
                                        title: Text(
                                          fileName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          "Created at: $createdTime",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700]),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.download,
                                              color: Colors.grey),
                                          onPressed: () {
                                            handleDownload(
                                                file.id ?? "unknown_id",
                                                fileName);
                                          },
                                        ),
                                        onTap: () {
                                          handleOpenPdf(file.id ?? "unknown_id",
                                              fileName);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  : (historyFilesDirectoryPath != null
                      ? RecentPdfWidget(
                          recentPdfs: [],
                          pdfDirectoryPath: historyFilesDirectoryPath!,
                        )
                      : Center(child: CircularProgressIndicator())),
            ),

            // Default message before filter selection
          ],
        ),

        // Chit tab to indicate folded menu (Desktop)
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          right: isMenuOpen
              ? 0
              : -MediaQuery.of(context).size.width *
                  0.2, // Menu fully hidden when folded
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.2,
          child: MouseRegion(
            onEnter: (_) => setState(
                () => isMenuOpen = true), // Slide out when mouse hovers
            onExit: (_) => setState(
                () => isMenuOpen = false), // Slide in when mouse leaves
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Sliding Menu Panel with transparent effect when folded
                Container(
                  color: isMenuOpen
                      ? const Color(0xFF103783)
                      : Colors
                          .transparent, // Red when open, transparent when closed
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Search Filters",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildListTile("Filter by Patient ID", selectedFilter,
                          _handleSelection),
                      _buildDivider(),
                      SizedBox(height: 20),
                      _buildListTile(
                          "Filter by Date", selectedFilter, _handleSelection),
                      _buildDivider(),
                      SizedBox(height: 20),
                      _buildListTile(
                          "List All Records", selectedFilter, _handleSelection),
                      _buildDivider(),
                    ],
                  ),
                ),

                // Empty Block without Filter Icon, only visible when the menu is folded
                if (!isMenuOpen) // This will only show when the menu is folded
                  Positioned(
                    left:
                        -20, // ensure it's slightly visible even when the menu is folded
                    top: 10, // place it at the top of the menu
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          // Toggle the menu open/closed on tap
                          isMenuOpen = !isMenuOpen;
                        });
                      },
                      child: Container(
                        width: 40, // square block width
                        height: 40, // square block height
                        decoration: BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(
                              8), // slightly rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        // No child inside, empty block
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Hover Strip (Now Fully Covers AppBar)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 10,
          child: MouseRegion(
            onEnter: (_) => setState(() => isMenuOpen = true),
            child: Container(
              color: Colors.grey[200],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildListTile(String title, String selected, Function(String) onTap) {
    return GestureDetector(
      onTap: () {
        onTap(title); // Update selection when tapped
      },
      child: Container(
        color: selected == title
            ? Colors.blueGrey[100] // Highlight selected item
            : Colors.transparent, // Default background
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected == title ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade400);
  }
}
