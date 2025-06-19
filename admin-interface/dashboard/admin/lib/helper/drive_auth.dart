import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class DriveAuth {
  static AuthClient? _client; // Singleton instance

  /// Returns an authenticated client, reusing it if already initialized.
  static Future<AuthClient> getHttpClient() async {
    if (_client != null) {
      return _client!; // Reuse existing client
    }

    try {
      // Load the service account JSON file
      final jsonString = await rootBundle
          .loadString('lib/credentials/service-account-key.json');
      final credentials =
          ServiceAccountCredentials.fromJson(jsonDecode(jsonString));

      // Define the required scopes
      final scopes = [drive.DriveApi.driveScope];

      // Authenticate and store the client
      _client = await clientViaServiceAccount(credentials, scopes);

      // **Success message**
      print("Successfully authenticated with Google Drive!");

      return _client!;
    } catch (e) {
      print("Authentication failed: $e");
      rethrow; // Rethrow the error so it can be handled by calling functions
    }
  }
}
