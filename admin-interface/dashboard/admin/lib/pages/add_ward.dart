import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import '../helper/downloadLocation.dart';
import 'package:open_file/open_file.dart';

class AddWard extends StatefulWidget {
  const AddWard({Key? key}) : super(key: key);

  @override
  _AddWardState createState() => _AddWardState();
}

class _AddWardState extends State<AddWard> {
  final TextEditingController _wardNameController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  final ApiService _apiService = ApiService();
  bool _isQRDownloaded = false;
  bool _isLoading = false;
  Map<String, dynamic>? _wardData;
  String? _errorMessage;
  String? wardNo;

  bool _isReissueMode = false;
  String? _selectedWardForReissue;
  final screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Ward QR Codes',
          style: GoogleFonts.roboto(
            color: const Color.fromARGB(255, 122, 121, 121),
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            onSelected: (value) async {
              if (_hasUnsavedData()) {
                final shouldProceed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Discard changes?'),
                    content:
                        Text('Switching roles will clear all entered data.'),
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

              setState(() {
                _isReissueMode = value == 'reissue';
                _resetForm();
                print("Mode Selected: $_isReissueMode"); // Debug log
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'add',
                  child: Text('Add New Ward'),
                ),
                PopupMenuItem<String>(
                  value: 'reissue',
                  child: Text('Reissue QR Code'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isReissueMode ? "Reissue Ward QR Code" : "Add New Ward",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF103783),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Show Dropdown if Reissue Mode
                  if (_isReissueMode) _buildWardDropdownForReissue(),
                  // Show TextField for Ward Name if Add Mode
                  if (!_isReissueMode)
              
                    TextField(
  controller: _wardNameController,
  decoration: InputDecoration(
    labelText: "Ward Name",
    labelStyle: TextStyle(
      color: Colors.grey[600], // Label color when not focused
    ),
    errorText: _errorMessage,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[400]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[400]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Color(0xFF103783), // Your deep blue color
        width: 2.0, // Slightly thicker border when focused
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.red, // Keep red for error state
        width: 2.0,
      ),
    ),
  ),
  enabled: !_isLoading,
  onSubmitted: (_) {
    if (_wardData == null) {
      _createWard();
    }
  },
  style: TextStyle(
    color: Colors.black87, // Text color
    fontSize: 16,
  ),
  cursorColor: Color(0xFF103783), // Matching cursor color
),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 450,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading) // Disable if loading OR QR exists
                                ? null
                                : () {
                                    if (_isReissueMode) {
                                      _reissueQRCode();
                                    } else {
                                      _createWard();
                                    }
                                  },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          backgroundColor: const Color(0xFF103783),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.qr_code,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isReissueMode
                                        ? "Reissue QR Code"
                                        : "Generate QR Code",
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
                  if (_wardData != null) ...[
                    const SizedBox(height: 20),
                    _buildQRView(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openQRFileForBed(int bedNo) async {
    try {
      // Step 1: Get the directory path
      final directory = await getMedoSubFolderPath('Ward QR Codes');

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
      print("❌ Error opening QR file for Bed No $bedNo: $e");
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

  Widget _buildWardDropdownForReissue() {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: _apiService.getAllWards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 50,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text('Error loading wards: ${snapshot.error}');
        }

        final wards = snapshot.data ?? []; // Handle null case with empty list

        return DropdownButtonFormField<String>(
          value: _selectedWardForReissue,
          hint: const Text('Select Ward'),
          items: wards.map<DropdownMenuItem<String>>((ward) {
            return DropdownMenuItem<String>(
              value: ward['wardName'], // Handle potential null wardNo
              child: Text(ward['wardName']?.toString() ?? 'Unknown Ward'),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedWardForReissue = value;
              _wardData = null;
              _errorMessage = null;
              print("🔁 Reissue state reset on dropdown change");
            });
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Select Ward',
            errorText: _errorMessage,
          ),
        );
      },
    );
  }

  Future<void> _reissueQRCode() async {
    if (_selectedWardForReissue == null) {
      setState(() => _errorMessage = "Please select a ward");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await _apiService.regenerateQRForWard(_selectedWardForReissue!);

      setState(() {
        _wardData = {
          'wardNo': response['ward']['wardNo'],
          'wardName': response['ward']['wardName'],
          'qrID': response['ward']['newQRID'].toString()
        };
        wardNo = response['ward']['wardNo'];
      });

      /// ✅ Automatically save the QR after reissuing
      await Future.delayed(Duration(milliseconds: 300)); // let QR render
      await _saveQRCode();
    } catch (e) {
      setState(() {
        _errorMessage =
            "Failed to reissue QR: ${e.toString().replaceAll("Exception: ", "")}";
      });
      print("QR reissue error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createWard() async {
    if (_wardNameController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter a ward name");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _wardData = null;
    });

    try {
      final wardData =
          await _apiService.createWard(_wardNameController.text.trim());

      if (wardData == null || wardData['ward'] == null) {
        throw Exception("Failed to create ward - no data returned");
      }

      setState(() {
        _wardData = {
          'wardNo': wardData['ward']['wardNo'],
          'wardName': wardData['ward']['wardName'],
          'qrID': wardData['ward']['qrID']
        };
        wardNo = wardData['ward']['wardNo'];
      });

      /// ✅ Automatically save the QR after generating
      await Future.delayed(
          Duration(milliseconds: 300)); // ensure UI has time to build QR
      await _saveQRCode();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
      print("Ward creation error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveQRCode() async {
    if (_wardData == null) return;

    try {
      // Get folder path
      String? wardFolderPath = await getMedoSubFolderPath('Ward QR Codes');

      if (wardFolderPath == null) {
        final pathProvider = PathProviderWindows();
        final downloadsDir = await pathProvider.getDownloadsPath();

        if (downloadsDir == null) {
          throw Exception("Could not access Downloads directory");
        }

        wardFolderPath = '$downloadsDir/MedoQRST/Ward QR Codes';
      }

      final appDir = Directory(wardFolderPath);
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final fileName =
          'QR_Ward_${_wardData!['wardNo']}${_wardData!['wardName']}'
              .replaceAll(RegExp(r'[^\w\d]+'), '_');
      final filePath = '${appDir.path}/$fileName.png';

      // ✅ Use the same on-screen screenshot method as used in Bed QR
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 4.0, // match bed QR resolution
      );

      if (imageBytes == null) {
        throw Exception("Failed to capture QR image from screen");
      }

      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);

      // Format the path to make it clear and display it in the SnackBar
      String formattedPath = filePath.replaceAll(RegExp(r'\\'), '/');

      print("FilePath before showing SnackBar: $filePath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR code saved to: $formattedPath',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.blueGrey[200],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
          duration: Duration(seconds: 3),
        ),
      );

      _isQRDownloaded = true;
      // _resetForm();
    } catch (e) {
      print("❌ Failed to save ward QR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save QR: ${e.toString()}',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.red.withOpacity(0.7),
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _wardNameController.clear();
      _wardData = null;
      _errorMessage = null;
      _selectedWardForReissue = null;
    });
  }

  Widget _buildQRView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF103783), width: 4),
              color: Colors.white,
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.only(
                top: 8, left: 24, right: 24, bottom: 8), //updated values
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white, // Ensure clean white background
                padding: EdgeInsets.only(
                    top: 8, left: 24, right: 24, bottom: 8), //updated values
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: '${wardNo}',
                      size: 280, //updated value
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
                      "${_wardData!['wardName']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Ward No: ${_wardData!['wardNo']}",
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
          Visibility(
            visible: _isQRDownloaded,
            child: TextButton.icon(
              onPressed: () async {
                try {
                  print(
                      "🖨️ Opening QR file for Ward: ${_wardData!['wardName']}");

                  // Generate the expected filename
               
                 final fileName = 'QR_Ward_${_wardData!['wardNo']}${_wardData!['wardName']}.png'
    .replaceAll(RegExp(r'[^\w\d.]+'), '_');  

                  // Get directory path where the file should exist
                  final directory = await getMedoSubFolderPath('Ward QR Codes');
                  final filePath = "$directory/$fileName";
                  print("The ward File Path: ${filePath}");

                  // Check if file exists
                  final file = File(filePath);
                  if (await file.exists()) {
                    print("✅ Found QR file at: $filePath");

                    // Open the existing file
                    final result = await OpenFile.open(filePath);
                    print("📂 File open result: ${result.message}");
                  } else {
                    print("❌ Error: QR file not found at $filePath");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "QR file not found. Please regenerate the QR code.")));
                  }
                } catch (e) {
                  print("❌ Error while opening QR file: $e");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text("Failed to open QR file: ${e.toString()}")));
                }
              },
              icon: Icon(Icons.print, color: Color(0xFF103783)),
              label: Text(
                "Print QR",
                style: TextStyle(
                  color: Color(0xFF103783),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  bool _hasUnsavedData() {
    return _wardData != null ||
        _wardNameController.text.isNotEmpty ||
        _selectedWardForReissue != null;
  }

  @override
  void dispose() {
    _wardNameController.dispose();
    super.dispose();
  }
}
