import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../helper/downloadLocation.dart';

class GoogleDriveService {
  late drive.DriveApi driveApi;
  late AuthClient client;
  bool isInitialized = false;

  /// ✅ Initialize Google Drive API
  Future<void> init() async {
    if (isInitialized) return;
    try {
      final jsonString = await rootBundle
          .loadString('lib/credentials/service-account-key.json');
      final credentials =
          ServiceAccountCredentials.fromJson(jsonDecode(jsonString));

      final scopes = [drive.DriveApi.driveScope];
      client = await clientViaServiceAccount(credentials, scopes);
      driveApi = drive.DriveApi(client);
      isInitialized = true;

      print("✅ Google Drive API initialized successfully!");
    } catch (e) {
      print("❌ Error initializing Google Drive API: $e");
    }
  }

  Future<List<drive.File>> getFilesByDate(DateTime selectedDate) async {
    await init();

    try {
      const medoFolderId = "1V70N9s1KIEV_hIdcwVEjkYQ3JC0e2oem";
      String dateFilter = DateFormat("yyyy-MM-dd").format(selectedDate);

      print(
          "🔍 Searching for files created on: $dateFilter in MedoQRST folder");

      String query = """
      '${medoFolderId}' in parents and
      createdTime >= '${dateFilter}T00:00:00Z' and
      createdTime < '${dateFilter}T23:59:59Z' and
      trashed = false and
      mimeType = 'application/pdf'
    """;

      String? pageToken;
      List<drive.File> filteredFiles = [];

      do {
        final response = await driveApi.files.list(
          q: query,
          $fields: "nextPageToken, files(id, name, createdTime, parents)",
          pageToken: pageToken,
          pageSize: 100,
        );

        final files = response.files ?? [];

        for (final file in files) {
          print("📄 ${file.name} - Created: ${file.createdTime}");
        }

        filteredFiles.addAll(files);
        pageToken = response.nextPageToken;
      } while (pageToken != null);

      if (filteredFiles.isNotEmpty) {
        print("✅ Found ${filteredFiles.length} file(s) on $dateFilter");
      } else {
        print("❌ No files found in MedoQRST folder for this date");
      }

      return filteredFiles;
    } catch (e) {
      print("❌ Error filtering files by date: $e");
      return [];
    }
  }

  Future<List<drive.File>> searchFile(String patientId) async {
    await init();

    try {
      print("🔄 searchFile() called for Patient ID: $patientId");

      const medoFolderId = "1V70N9s1KIEV_hIdcwVEjkYQ3JC0e2oem";
      // final fileNameToSearch = "HF_$patientId.pdf";
      final RegExp fileNameToSearch =
          RegExp(r'^HF_\d{6}_' + patientId + r'\.pdf$');

      // STEP 1: List all files inside MedoQRST folder
      final listQuery =
          "'$medoFolderId' in parents and trashed = false and mimeType = 'application/pdf'";
      String? pageToken;
      final matchingFiles = <drive.File>[];

      print("📁 Listing all PDF files in MedoQRST folder...");

      do {
        final response = await driveApi.files.list(
          q: listQuery,
          spaces: 'drive',
          $fields: "nextPageToken, files(id, name, createdTime, parents)",
          corpora: 'user',
          pageToken: pageToken,
          pageSize: 100,
        );

        final files = response.files ?? [];

        // for (final file in files) {
        //   print("📝 ${file.name}");

        //   if (file.name == fileNameToSearch) {
        //     matchingFiles.add(file);
        //   }
        // }

        for (final file in files) {
          print("📝 ${file.name}");

          if (fileNameToSearch.hasMatch(file.name ?? '')) {
            matchingFiles.add(file);
          }
        }

        pageToken = response.nextPageToken;
      } while (pageToken != null);

      if (matchingFiles.isNotEmpty) {
        print(
            "✅ Found matching file(s): ${matchingFiles.map((f) => f.name).toList()}");
      } else {
        print("❌ No file found for: $fileNameToSearch in MedoQRST folder");
      }

      return matchingFiles;
    } catch (e) {
      print("❌ Error while searching file: $e");
      return [];
    }
  }

  Future<List<drive.File>> listAllFiles() async {
    await init();
    try {
      const medoFolderId =
          "1V70N9s1KIEV_hIdcwVEjkYQ3JC0e2oem"; // MedoQRST folder ID
      List<drive.File> allOwnedFiles = [];
      String? pageToken;

      do {
        var fileList = await driveApi.files.list(
          q: "'$medoFolderId' in parents and trashed = false", // Filter by MedoQRST folder
          pageSize: 100,
          pageToken: pageToken,
          $fields:
              "nextPageToken, files(id, name, createdTime, parents, ownedByMe)",
        );

        final files = fileList.files ?? [];

        // Only include files owned by the current account and not orphaned
        final validFiles = files
            .where((file) =>
                (file.ownedByMe ?? false) &&
                file.parents != null &&
                file.parents!.isNotEmpty)
            .toList();

        allOwnedFiles.addAll(validFiles);
        pageToken = fileList.nextPageToken;
      } while (pageToken != null);

      print(
          "📦 Total owned files found in MedoQRST folder: ${allOwnedFiles.length}");
      return allOwnedFiles;
    } catch (e) {
      print("❌ Error fetching files: $e");
      return [];
    }
  }

// //function to download file from drive
//   Future<Uint8List?> downloadFileFromDrive(
//       String fileId, String fileName) async {
//     try {
//       drive.Media fileData = await driveApi.files.get(
//         fileId,
//         downloadOptions: drive.DownloadOptions.fullMedia,
//       ) as drive.Media;

//       List<int> dataStore = [];
//       await for (var chunk in fileData.stream) {
//         dataStore.addAll(chunk);
//       }

//       print("File $fileName downloaded successfully!");
//       return Uint8List.fromList(dataStore);
//     } catch (e) {
//       print("Download failed: $e");
//       return null;
//     }
//   }

  Future<Uint8List?> downloadFileFromDrive(
      String fileId, String fileName) async {
    try {
      drive.Media fileData = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      List<int> dataStore = [];
      await for (var chunk in fileData.stream) {
        dataStore.addAll(chunk);
      }

      Uint8List fileBytes = Uint8List.fromList(dataStore);

      // ✅ Use your global helper to get the download path
      String? folderPath = await getMedoSubFolderPath('History Files');
      if (folderPath == null) {
        print("❌ Download location not found.");
        return null;
      }

      final filePath = '$folderPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      print("✅ File saved at: $filePath");

      return fileBytes;
    } catch (e) {
      print("❌ Download failed: $e");
      return null;
    }
  }

  Future<String?> openPdfFromDrive(String fileId, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Download from Drive
      drive.Media fileData = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      List<int> dataStore = [];
      await for (var chunk in fileData.stream) {
        dataStore.addAll(chunk);
      }

      // Overwrite or create new file
      await file.writeAsBytes(dataStore);

      return filePath;
    } catch (e) {
      print("❌ Error opening PDF: $e");
      return null;
    }
  }

  Future<String?> getFolderId(String folderName) async {
    await init();
    try {
      String query =
          "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final drive.FileList response = await driveApi.files.list(q: query);

      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id; // Return the first matching folder ID
      } else {
        print("❌ Folder not found: $folderName");
        return null;
      }
    } catch (e) {
      print("❌ Error getting folder ID: $e");
      return null;
    }
  }

  // Future<bool> uploadPdfsToDrive(List<File> pdfFiles) async {
  //   await init();

  //   const medoFolderId =
  //       "1V70N9s1KIEV_hIdcwVEjkYQ3JC0e2oem"; // Fixed MedoQRST folder ID

  //   try {
  //     bool allUploadsSuccessful = true;

  //     for (File pdfFile in pdfFiles) {
  //       try {
  //         String fileName = p.basename(pdfFile.path);
  //         var media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());

  //         var driveFile = drive.File()
  //           ..name = fileName
  //           ..parents = [medoFolderId];

  //         final uploadedFile = await driveApi.files.create(
  //           driveFile,
  //           uploadMedia: media,
  //         );

  //         print("✅ Uploaded: ${uploadedFile.name} to MedoQRST folder");
  //       } catch (fileError) {
  //         print("❌ Failed to upload ${pdfFile.path}: $fileError");
  //         allUploadsSuccessful = false;
  //       }
  //     }

  //     return allUploadsSuccessful;
  //   } catch (e) {
  //     print("❌ Upload process error: $e");
  //     return false;
  //   }
  // }

  Future<bool> uploadPdfsToDrive(Uint8List pdfBytes, String fileName) async {
    await init();

    const medoFolderId = "1V70N9s1KIEV_hIdcwVEjkYQ3JC0e2oem";

    try {
      var media = drive.Media(
        Stream.value(pdfBytes), // use the byte stream directly
        pdfBytes.length,
      );

      var driveFile = drive.File()
        ..name = fileName
        ..parents = [medoFolderId];

      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      print("✅ Uploaded directly: ${uploadedFile.name}");
      return true;
    } catch (e) {
      print("❌ Direct upload failed: $e");
      return false;
    }
  }
}
