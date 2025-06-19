import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

// Global Helper Function
Future<String?> getMedoSubFolderPath(String subFolderName,
    {String? selectedWard}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? medoBasePath = prefs.getString('download_location');

  if (medoBasePath != null) {
    // Base path for the subfolder
    String fullPath = '$medoBasePath/$subFolderName';

    // If selectedWard is provided (for BedQRCodes), create a ward-specific subfolder
    if (selectedWard != null) {
      fullPath = '$fullPath/$selectedWard';

      // Check if the ward folder exists
      Directory wardFolder = Directory(fullPath);
      if (!await wardFolder.exists()) {
        // Create the folder if it doesn't exist
        await wardFolder.create(recursive: true);
        print("✅ Ward folder created: $fullPath");
      }
    }

    return fullPath; // Return the path to the folder (with or without ward subfolder)
  }

  return null; // Return null if base path is not found
}
