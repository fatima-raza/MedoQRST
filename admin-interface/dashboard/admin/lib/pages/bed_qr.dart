import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ward_details.dart';
import '../services/addBed_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import '../helper/downloadLocation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:open_file/open_file.dart';

import 'bedcount.dart';

class AddBedScreen extends StatefulWidget {
  const AddBedScreen({Key? key}) : super(key: key);

  @override
  _AddBedScreenState createState() => _AddBedScreenState();
}

class _AddBedScreenState extends State<AddBedScreen> {
  int selectedBedCount = 2; // Default value
  String? selectedWard;
  String? selectedWardNo;
  bool isSingleBed = true;
  // TextEditingController bedCountController = TextEditingController();
  String bedNumberingOption = "Continue";
  TextEditingController numberingValueController = TextEditingController();
  List<String> wards = [];
  Map<String, String> wardMap = {};
  FocusNode wardFocusNode = FocusNode();
  Color wardTextColor = Color.fromARGB(255, 122, 121, 121);
  bool isLoading = false;
  String? noBedFoundMessage;
  List<String> wardList = []; // Instead of List<Map<String, dynamic>>
  final ScreenshotController screenshotController = ScreenshotController();
  String? bedNo;
  Map<String, dynamic>? QRdata = {}; // Instead of null
  // ✅ Initialize as null
  bool isQRDownloaded = false; // Track if QR has been downloaded
  int bedCount = 2;
  TextEditingController bedCountController = TextEditingController(text: "2");
  Map<String, dynamic>? currentQR; // ✅ Stores the currently displayed QR
  bool isQRGenerated = false;
  bool showRefreshButton = false;
  List<Widget> _qrWidgets = [];
  bool isExistingBedMode = false;
  TextEditingController existingBedController = TextEditingController();
  bool _showError = false;
  TextEditingController bednoController = TextEditingController();
  final FocusNode IDFocusNode = FocusNode();
  bool showMultipleQRList = false;
  final layerLink = LayerLink();

  bool isValidBedNumber(String value) {
    if (value.isEmpty) return false;
    final number = int.tryParse(value);
    return number != null && number > 0;
  }

  @override
  void initState() {
    super.initState();

    print("🛠️ Calling loadWardData in initState...");
    loadWardData();
    resetForm();
  }

//This function will call the api to get the available ward names to display in the ward drop down
  Future<void> loadWardData() async {
    Map<String, String> fetchedWardMap = await WardService.fetchWardData();
    setState(() {
      wardMap = fetchedWardMap;
    });
  }

// Callback function to update selectedBedCount
  void onBedCountChanged(int count) {
    setState(() {
      selectedBedCount = count;
    });
    print("Selected beds updated: $selectedBedCount");
  }

  Future<void> openDownloadedQR(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      print("File does not exist");
      return;
    }

    final uri = Uri.file(filePath);

    if (!await launchUrl(uri)) {
      print('Could not launch file');
    }
  }

//This function will make the api call and get the QR ID  and BedNo (stores in QRdata) from the database
  Future<void> Get_QR_ID(String wardNo, bool isSingleBed) async {
    setState(() {
      isLoading = true;
      QRdata = null; // ✅ Clear previous data before API call
    });

    try {
      final result = await AddbedService.generateQRCode(
          wardNo, isSingleBed, selectedBedCount);

      setState(() {
        if (result != null) {
          // Manually add 'wardName' to the result (QRdata)
          result['wardName'] = selectedWard;
          print('result ${result}'); // Add wardName to QRdata

          QRdata = result; // Update QRdata with the result including wardName
          print("✅ Updated QRdata: $QRdata"); // Debugging log
        } else {
          print("❌ API returned null");
        }
      });
    } catch (e) {
      print("❌ ERROR: $e");
    } finally {
      setState(() {
        isLoading = false; // ✅ Ensure loading stops
        // selectedWardNo = null; // ✅ Reset wardNo after request
      });
    }
  }

  //this function will download the QRs incase of multiple QR generation at a time
  Future<void> saveMultipleQRs(
      List<Widget> qrWidgets, String downloadsDir) async {
    if (QRdata == null || !QRdata!.containsKey('beds')) {
      print("❌ Error: No QR code data available!");
      return;
    }

    List beds = QRdata!['beds'];
    for (int i = 0; i < beds.length; i++) {
      String bedNo = beds[i]['bedNo'].toString();

      try {
        // Important: Make sure the qrWidgets list is long enough
        if (i >= qrWidgets.length) {
          print("⚠️ QR widget not ready for Bed No: $bedNo at index $i");
          continue;
        }

        final Uint8List? imageBytes =
            await screenshotController.captureFromWidget(
          qrWidgets[i],
          pixelRatio: 8.0,
        );

        if (imageBytes == null) {
          print("❌ Error capturing QR code for Bed No: $bedNo");
          continue;
        }

        String filePath = '$downloadsDir/QR_BedNo_$bedNo.png';
        File file = File(filePath);
        await file.writeAsBytes(imageBytes);

        print("✅ High-res QR Code for Bed No: $bedNo saved at: $filePath");
      } catch (e) {
        print("❌ Error saving QR Code for Bed No $bedNo: $e");
      }

      // ✅ Move state update here after all QRs have been processed
      if (mounted) {
        // `mounted` ensures the widget is still in the tree
        setState(() {
          isLoading = false;
          showMultipleQRList = true;
        });
      }
    }
  }

  Future<void> openQRFileForBed(int bedNo) async {
    try {
      // Step 1: Get the directory path
      final directory = await getMedoSubFolderPath('Bed QR Codes',
          selectedWard: selectedWard);

      if (directory == null) {
        print("❌ Failed to get directory path");
        return;
      }

      // Step 2: Construct the full file path
      final filePath = "$directory/QR_BedNo_$bedNo.png";
      final file = File(filePath);

      // Step 3: Check if the file exists
      if (await file.exists()) {
        print("📂 Opening file: $filePath");
        await OpenFile.open(filePath);
      } else {
        print("⚠️ File does not exist for Bed No: $bedNo");
      }
    } catch (e) {
      print("❌ Error opening QR code file for Bed No $bedNo: $e");
    }
  }

//this function will download the QR incase of  single QR generation at a time
  Future<void> _saveSingleQRCode(
      Map<String, dynamic> qrData, String downloadsDir) async {
    try {
      // ✅ Capture QR code from screen
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 4.0, // ✅ High quality
      );

      if (imageBytes == null) {
        print("❌ Error: Screenshot capture failed!");
        return;
      }

      String bedNo =
          qrData.containsKey('bedNo') ? qrData['bedNo'].toString() : "Unknown";
      String filePath = '$downloadsDir/QR_BedNo_$bedNo.png';

      File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      print("✅ QR Code saved at: $filePath");
    } catch (e) {
      print("❌ Error saving QR Code: $e");
    }
  }

  Future<void> regenerateQRForExistingBed(String wardNo, int bedNo) async {
    print("Regenerating QR code for Ward $wardNo, Bed $bedNo");

    setState(() {
      isLoading = true;
      QRdata = null;
      noBedFoundMessage = null; // ✅ Clear previous error message
    });

    try {
      final result = await AddbedService.generateQRCode(
          wardNo,
          true, // ✅ still pass `true` for isSingleBed to reuse function
          null, // ✅ no selectedBedCount needed in regenerate mode
          bedNo // ✅ pass existing bedNo
          );

      setState(() {
        if (result != null && result['error'] == true) {
          // ✅ Received error from backend, display message
          noBedFoundMessage = result['message'];
          print("❌ API Error: $noBedFoundMessage");
        } else if (result != null) {
          // ✅ Successful QR regeneration
          result['wardName'] = selectedWard; // Optional: include ward name
          QRdata = result;
          print("✅ Updated QRdata (regenerated): $QRdata");
        } else {
          // ✅ Fallback if somehow result is null
          noBedFoundMessage = "Failed to regenerate QR (unknown error)";
          print("❌ Failed to regenerate QR (null result)");
        }
      });
    } catch (e) {
      setState(() {
        noBedFoundMessage = "An unexpected error occurred: $e";
      });
      print("❌ Exception during QR regeneration: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

//On pressing download QR or download all Button in single QR and multiple QR case respectively this function will work to get the download directory path and then the further logic for handling both the cases is splitted using if/else block
  Future<void> routeBasedOnQRType(
      {bool isSingleBed = true,
      List<Widget>? qrWidgets,
      required String selectedWard}) async {
    try {
      // Call the global helper function to get the ward-specific folder path
      String? subFolderPath = await getMedoSubFolderPath('Bed QR Codes',
          selectedWard: selectedWard);

      if (subFolderPath == null) {
        print("❌ Error: Unable to access selected Downloads folder!");
        // Display error via Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Unable to access selected Downloads folder.",
                  style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.red.withOpacity(0.7)),
        );
        return;
      }

      Widget qrDisplay = buildQRDisplay(QRdata, onBuilt: () async {
        if (!isSingleBed && _qrWidgets != null) {
          print('Going For multiple QR dowwnloads');
          await saveMultipleQRs(_qrWidgets, subFolderPath);
        } else {
          // Prepare the file path yourself before saving
          String bedNo = QRdata!.containsKey('bedNo')
              ? QRdata!['bedNo'].toString()
              : "Unknown";
          String savedFilePath = "$subFolderPath/QR_BedNo_$bedNo.png";
          print('Going inside the function to download Single QR!');
          await _saveSingleQRCode(QRdata!, subFolderPath);
        }
      });
    } catch (e) {
      print("❌ Error saving QR Code: $e");
      // Show error message with Snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Something went wrong while saving the QR Code.",
              style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.red.withOpacity(0.7)));
    }
  }

//     if ( !isSingleBed && qrWidgets != null) {
//       // await saveAllQRs(qrWidgets, subFolderPath); // ✅ Save multiple QRs
//       await saveMultipleQRs(qrWidgets, subFolderPath );
//       setState(() {
//          isLoading = false;
//   showMultipleQRList = true;
// });

//       // Show success message with Snackbar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("All QR Codes have been saved at $subFolderPath",
//          style: TextStyle(color: Colors.black)),
//           backgroundColor: Colors.blueGrey[200],
//         ),
//       );
//     }
//     else {
//   // Prepare the file path yourself before saving
//   String bedNo = QRdata!.containsKey('bedNo') ? QRdata!['bedNo'].toString() : "Unknown";
//   String savedFilePath = "$subFolderPath/QR_BedNo_$bedNo.png";

//   await _saveSingleQRCode(QRdata!, subFolderPath);

//   // Show success message with Snackbar
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text("QR Code saved successfully at $savedFilePath", style: TextStyle(color: Colors.black)),
//       backgroundColor: Colors.blueGrey[200],
//     ),
//   );

//   // 💡 Show user dialog to open the QR now
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Text("QR Saved"),
//       content: Text("Do you want to open the saved QR code now?"),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//             openDownloadedQR(savedFilePath);
//           },
//           child: Text("Yes"),
//         ),
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           child: Text("No"),
//         ),
//       ],
//     ),
//   );
//   resetForm(); //reset form
// }

//   }
//   catch (e) {
//     print("❌ Error saving QR Code: $e");
//     // Show error message with Snackbar
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Something went wrong while saving the QR Code.",
//  style: TextStyle(color: Colors.black)),
//   backgroundColor: Colors.red.withOpacity(0.7) )
//     );
//   }
// }

  void resetForm() {
    setState(() {
      isQRGenerated = false; // ✅ Re-enable form fields
      QRdata = null; // ✅ Clear previous QR data
      isSingleBed = true; // ✅ Reset to default selection
      // selectedWard = null; // ✅ Clear selected ward
      // selectedWardNo = null; // ✅ Clear selected ward number
    });
  }

//QR display for single bed insertion
//   Widget _buildSingleQR(Map<String, dynamic> QRdata) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,

// children: [
//   // This text can be removed as it has already been added below the QR
//   SizedBox(height: 10),
//   Container(
//     width: 400,
//     height: 400,
//     decoration: BoxDecoration(
//       border: Border.all(color: const Color(0xFF103783), width: 4),
//       color: Colors.white,
//     ),
//     alignment: Alignment.center,
//     padding: EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 8),
//     child: Screenshot(
//       controller: screenshotController,
//       child: Container(
//         color: Colors.white, // Ensure clean white background
//         padding: EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             QrImageView(
//               data: '${QRdata['wardNo']} ${QRdata['bedNo']}',
//               size: 280, // Adjusted size of QR code
//               backgroundColor: Colors.white,
//               eyeStyle: QrEyeStyle(
//                 eyeShape: QrEyeShape.square,
//                 color: const Color(0xFF103783),
//               ),
//               dataModuleStyle: QrDataModuleStyle(
//                 dataModuleShape: QrDataModuleShape.square,
//                 color: const Color(0xFF103783),
//               ),
//             ),
//             SizedBox(height: 10),
//             Text(
//               " ${QRdata['wardName']}",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//             Text(
//               "Bed No: ${QRdata['bedNo']}",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ),
//   SizedBox(height: 10),

// ],

//       ),
//     );
//   }

  Widget _buildSingleQR(Map<String, dynamic> QRdata) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF103783), width: 4),
              color: Colors.white,
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.all(8),
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: '${QRdata['wardNo']} ${QRdata['bedNo']}',
                      size: 280,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: const Color(0xFF103783),
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: const Color(0xFF103783),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "${QRdata['wardName']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Bed No: ${QRdata['bedNo']}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),

          /// 🖨️ Print Button
          TextButton.icon(
            onPressed: () async {
              print("🖨️ Print requested for Bed No: ${QRdata['bedNo']}");

              final fileName =
                  "${QRdata['wardName']}_Bed_${QRdata['bedNo']}.png";

              final directory = await getMedoSubFolderPath(
                'Bed QR Codes',
                selectedWard: QRdata['wardName'],
              );

              final filePath = "$directory/$fileName";

              final image = await screenshotController.capture();
              if (image != null) {
                final file = File(filePath);
                await file.writeAsBytes(image);
                print("✅ Saved: $filePath");

                // Open the file
                await OpenFile.open(filePath);
              } else {
                print("❌ Error: Image capture failed.");
              }
            },
            icon: Icon(Icons.print, color: Color(0xFF103783)),
            label: Text(
              "Print QR code",
              style: TextStyle(
                color: Color(0xFF103783),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

// QR display for Multiple bed insertion
  Widget buildQRDisplay(Map<String, dynamic>? QRdata, {VoidCallback? onBuilt}) {
    if (QRdata == null || QRdata.isEmpty) {
      print("❌ API returned null or empty data!");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Something went wrong. Try refreshing the page!",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                print("🔄 Refresh button clicked!");
                resetForm(); // ✅ Refresh logic
              },
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text("Refresh"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      );
    }

    print("🔍 Checking if QRdata contains 'beds'...");

    if (QRdata.containsKey('beds')) {
      print("✅ 'beds' key exists, executing QR code display block");
      print("📊 Total beds found: ${QRdata['beds'].length}");
      // Step 1: Generate a list of unique GlobalKeys (before your map)
      List<GlobalKey> qrKeys =
          List.generate(QRdata['beds'].length, (_) => GlobalKey());
      // Step 2: Map through beds and assign each GlobalKey

      List<Widget> qrWidgets =
          QRdata['beds'].asMap().entries.map<Widget>((entry) {
        int index = entry.key;
        var bed = entry.value;

        Map<String, dynamic> qrData = {
          "bedNo": bed['bedNo'],
          // "qrId": bed['qrId'],
          "wardName": selectedWard,
        };

        return RepaintBoundary(
          key: qrKeys[index], // unique GlobalKey per item
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  // data: json.encode(qrData),
                  data: '${bed['wardNo']} ${bed['bedNo']}',
                  size: 206,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: const Color(0xFF103783),
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: const Color(0xFF103783),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  " ${selectedWard ?? 'Unknown Ward'}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Bed No: ${bed['bedNo']}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();

      // 🔹 Store in state variable
      setState(() {
        _qrWidgets = qrWidgets;
      });
      // 🕒 Trigger callback after the frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (onBuilt != null) onBuilt();
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ensure content is not stretched
        children: [
          if (showMultipleQRList)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: QRdata['beds'].length,
              itemBuilder: (context, index) {
                int bedNo = QRdata['beds'][index]['bedNo'];

                return ListTile(
                  leading:
                      Icon(Icons.qr_code_2, color: const Color(0xFF103783)),
                  title: Text("QR Code for Bed No: $bedNo"),
                  trailing: IconButton(
                    icon: Icon(Icons.print, color: const Color(0xFF103783)),
                    onPressed: () async {
                      print("🖨️ Print requested for Bed No: $bedNo");

                      await openQRFileForBed(bedNo);
                    },
                  ),
                  onTap: () {
                    print("🔍 Previewing QR code for Bed No: $bedNo");
                    _showQRPreview(context, bedNo, qrWidgets[index]);
                  },
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      );
    }

    print("❌ 'beds' key not found, returning alternative view");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onBuilt != null) onBuilt();
    });

    return _buildSingleQR(QRdata); // Handle case when only one bed exists
  }

//✅ **Updated Preview Function**
  void _showQRPreview(BuildContext context, int bedNo, Widget qrWidget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("QR Code Preview"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12), // Adds spacing between text and QR
              Screenshot(
                controller: screenshotController,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF103783), width: 4),
                    color: Colors.white,
                  ),
                  child: qrWidget, // ✅ Pre-generated QR widget
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Close",
                  style: TextStyle(color: const Color(0xFF103783))),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

//if user clicks Generate QR button without selecting ward. this function will run and an alert dialog will be displayed
  void _showAlertDialog(String title, String message,
      {bool showRefreshButton = false}) {
    Widget actionButton;

    if (title == "Select Ward") {
      actionButton = TextButton(
        onPressed: () {
          Navigator.pop(context); // ✅ Close dialog
        },
        child: Text("OK"),
      );
    } else if (title == "Error") {
      actionButton = TextButton(
        onPressed: () {
          Navigator.pop(context); // ✅ Close dialog
          setState(() {}); // ✅ Trigger a refresh (or call a refresh function)
        },
        child: Text("Refresh"),
      );
    } else if (title == "Download Required") {
      actionButton = TextButton(
        onPressed: () {
          print(
              'routeBasedOnQRType called from: Download Required dialog button');
          Navigator.pop(context); // ✅ Close dialog
          routeBasedOnQRType(
              isSingleBed: false,
              qrWidgets: _qrWidgets,
              selectedWard: selectedWard!); // ✅ Trigger QR download
        },
        child: Text(isSingleBed ? "Download" : "Download All"),
      );
    } else {
      actionButton = TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text("OK"),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            actionButton,
          ],
        );
      },
    );
  }

  void handleQRButtonPress() async {
    // ✅ Check if a ward is selected
    if (selectedWardNo == null && !isQRGenerated) {
      _showAlertDialog(
        "Select Ward",
        "Please select a ward before generating a QR code.",
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ✅ Check mode: Existing Bed or New Beds
      if (isExistingBedMode) {
        // 🔒 Validate entered bed number
        String input = existingBedController.text.trim();
        if (input.isEmpty) {
          _showAlertDialog("Missing Bed Number", "Please enter a bed number.");
          setState(() {
            isLoading = false;
          });
          return;
        }

        int? bedNumber = int.tryParse(input);
        if (bedNumber == null || bedNumber <= 0) {
          _showAlertDialog("Invalid Bed Number",
              "Please enter a valid positive integer (starting from 1).");
          setState(() {
            isLoading = false;
          });
          return;
        }

        setState(() {
          isQRGenerated = true;
          isQRDownloaded = false;
        });

        await regenerateQRForExistingBed(selectedWardNo!, bedNumber);
        print(
            'routeBasedOnQRType called from: regenerateQRForExistingBed flow');
        routeBasedOnQRType(selectedWard: selectedWard!);
      } else {
        if (isQRGenerated && (QRdata == null || QRdata!.isEmpty)) {
          _showAlertDialog(
            "Error",
            "Something went wrong. Try refreshing the page!",
            showRefreshButton: true,
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        setState(() {
          isQRGenerated = true;
          isQRDownloaded = false;
        });

        if (isSingleBed) {
          await Get_QR_ID(selectedWardNo!, true);
          print('routeBasedOnQRType called from: Get_QR_ID flow - SINGLE bed');
          routeBasedOnQRType(
              selectedWard: selectedWard!); // Default isSingleBed=true
        } else {
          await Get_QR_ID(selectedWardNo!, false);
          print(
              'routeBasedOnQRType called from: Get_QR_ID flow - MULTIPLE beds');
          routeBasedOnQRType(
            selectedWard: selectedWard!,
            isSingleBed: false,
            qrWidgets: _qrWidgets,
          );
        }
      }

      setState(() {
        isQRGenerated = false;
        isQRDownloaded = true;
        // selectedWard = null;
        // selectedWardNo = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
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
          isExistingBedMode
              ? 'Regenerate QR code'
              : 'Add New Bed', // Dynamic title based on isExistingBedMode
          style: GoogleFonts.roboto(
            color: const Color.fromARGB(255, 122, 121, 121),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔵 TextButton for existing bed QR
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton.icon(
                  //     onPressed: () {
                  //       setState(() {
                  //         // Toggle between modes
                  //         isExistingBedMode = !isExistingBedMode;

                  //         // Reset related states on mode switch
                  //         selectedWardNo = null;
                  //         selectedWard = null;
                  //         isSingleBed = true;
                  //         isQRGenerated = false;
                  //         QRdata = null;
                  //         bedNo = null;
                  //         noBedFoundMessage = null;
                  //         existingBedController
                  //             .clear(); // ✅ Clear input bed number field
                  //       });
                  //     },
                  //     icon: Icon(Icons.refresh, color: Color(0xFF103783)),
                  //     label: Text(
                  //       isExistingBedMode
                  //           ? 'Add New Bed'
                  //           : 'QR code for Existing Bed',
                  //       style: TextStyle(
                  //         color: Color(0xFF103783),
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //     ),
                  //   ),
                  // ),

Align(
  alignment: Alignment.centerRight,
  child: InkWell(
    onTap: () {
      setState(() {
        isExistingBedMode = !isExistingBedMode;
        selectedWardNo = null;
        selectedWard = null;
        isSingleBed = true;
        isQRGenerated = false;
        QRdata = null;
        bedNo = null;
        noBedFoundMessage = null;
        existingBedController.clear();
      });
    },
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExistingBedMode ? Icons.bed_outlined : Icons.qr_code,
            size: 20,
            color: Color(0xFF103783),
          ),
          SizedBox(width: 8),
          Text(
            isExistingBedMode ? 'Add New Bed' : 'Regenerate QR code',
            style: TextStyle(
              color: Color(0xFF103783),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  ),
),
DropdownButtonFormField<String>(
  value: selectedWard,
  hint: Text(
    "Select Ward",
    style: TextStyle(
      color: Colors.grey[600],
      fontSize: 16,
    ),
  ),
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Colors.grey[400]!,
        width: 1.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Colors.grey[400]!,
        width: 1.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Color(0xFF103783),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Colors.red,
        width: 1.5,
      ),
    ),
  ),
  style: TextStyle(
    color: Colors.black87,
    fontSize: 16,
  ),
  dropdownColor: Colors.white,
  icon: Icon(
    Icons.arrow_drop_down,
    color: Colors.grey[600],
    size: 28,
  ),
  iconSize: 24,
  elevation: 4,
  borderRadius: BorderRadius.circular(10),
  isExpanded: true,  // Important for proper alignment
  items: wardMap.keys.map((String wardName) {
    return DropdownMenuItem<String>(
      value: wardName,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          wardName,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }).toList(),
  onChanged: isQRGenerated
      ? null
      : (value) {
          if (value != null) {
            setState(() {
              selectedWard = value;
              selectedWardNo = wardMap[value];
            });
          }
        },
  selectedItemBuilder: (BuildContext context) {
    return wardMap.keys.map<Widget>((String wardName) {
      return Text(
        wardName,
        style: TextStyle(
          color: Color(0xFF103783),
          fontWeight: FontWeight.w500,
        ),
      );
    }).toList();
  },
),

                  isExistingBedMode
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                                height: 30,
                                thickness: 1,
                                color: Colors.grey.shade400),
                            TextField(
                                controller: existingBedController,
                                focusNode: IDFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: "Enter Bed No",
                                  labelStyle: GoogleFonts.roboto(
                                    color: IDFocusNode.hasFocus
                                        ? const Color.fromARGB(
                                            255, 122, 121, 121)
                                        : Colors.grey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _showError &&
                                              existingBedController.text.isEmpty
                                          ? Colors.red
                                          : const Color.fromARGB(
                                              255, 122, 121, 121),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _showError &&
                                              existingBedController.text.isEmpty
                                          ? Colors.red
                                          : Colors.blue.shade900,
                                      width: 2,
                                    ),
                                  ),
                                  errorText: _showError &&
                                          existingBedController.text.isEmpty
                                      ? 'Enter a number starting from 1'
                                      : null,
                                ),
                                onChanged: (value) {
                                  if (_showError) {
                                    setState(
                                        () {}); // Update error highlighting on input change after button press
                                  }
                                },
                                cursorColor:
                                    const Color.fromARGB(255, 122, 121, 121)),
                            Divider(
                                height: 30,
                                thickness: 1,
                                color: Colors.grey.shade400),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                                height: 30,
                                thickness: 1,
                                color: Colors.grey.shade400),
                            Text(
                              "Bed Settings",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF103783),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text("Do You want to add:",
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: isSingleBed,
                                  onChanged: isQRGenerated
                                      ? null
                                      : (value) {
                                          setState(() => isSingleBed = true);
                                        },
                                ),
                                Text("Single Bed"),
                                Spacer(),
                                Checkbox(
                                  value: !isSingleBed,
                                  onChanged: isQRGenerated
                                      ? null
                                      : (value) {
                                          setState(() => isSingleBed = false);
                                        },
                                ),
                                Text("Multiple Beds"),
                              ],
                            ),
                            Divider(
                                height: 30,
                                thickness: 1,
                                color: Colors.grey.shade400),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Number of Beds to be added:",
                                    style: TextStyle(fontSize: 16)),
                                SizedBox(height: 10),
                                Opacity(
                                  opacity:
                                      isSingleBed || isQRGenerated ? 0.5 : 1.0,
                                  child: IgnorePointer(
                                    ignoring: isSingleBed || isQRGenerated,
                                    child: BedCounter(
                                      onBedCountChanged: onBedCountChanged,
                                      onReset: resetForm,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                                height: 30,
                                thickness: 1,
                                color: Colors.grey.shade400),
                          ],
                        ),

                  Center(
                    child: SizedBox(
                      width: 450,
                      child: ElevatedButton(
                        onPressed:
                            (isLoading || (isQRGenerated && !isQRDownloaded))
                                // onPressed: (isLoading || isQRGenerated)
                                ? null
                                : handleQRButtonPress,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFF103783),
                          elevation: 5,
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.grey)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Generate QR code",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // QRdata != null ? buildQRDisplay(QRdata!) : SizedBox.shrink(),
                  QRdata != null
                      ? buildQRDisplay(QRdata!)
                      : (isExistingBedMode && noBedFoundMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Error Message Text
                                  Text(
                                    "Requested Bed Number does not exist",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.normal, // ❗ Not bold
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 20),

                                  // Re-enter Bed Number Button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Color(
                                          0xFF103783), // ❗ Deep blue text color
                                      backgroundColor: Colors
                                          .white, // ❗ White background for contrast
                                      side: BorderSide(
                                          color: Color(
                                              0xFF103783)), // ❗ Deep blue border
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0, // Flat look
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isQRGenerated = false;
                                        isQRDownloaded = false;
                                        noBedFoundMessage = null;
                                      });
                                    },
                                    child: Text("Re-enter Bed Number"),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
