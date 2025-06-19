import 'package:admin/services/network_client.dart';

class UsersServices {
  static final dio = NetworkClient.dio;

  // patient details
  static Future<Map<String, dynamic>?> getPatientDetails(
      String admissionId) async {
    try {
      final response = await dio.get('/users/$admissionId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getPatientDetails: $e");
      return null;
    }
  }

  // Patient Registration Details API
  static Future<Map<String, dynamic>?> getRegistrationDetails(
      String admissionId) async {
    try {
      final response = await dio.get('/details/$admissionId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getRegistrationDetails: $e");
      return null;
    }
  }

  // NextOfKin API
  static Future<Map<String, dynamic>?> getNextOfKinDetails(
      String admissionID) async {
    try {
      final response = await dio.get('/nextofkin/$admissionID');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getNextOfKinDetails: $e");
      return null;
    }
  }

  // Vitals API
  static Future<Map<String, dynamic>?> getVitals(String admissionID) async {
    try {
      final response = await dio.get('/vitals/$admissionID');
      print("Response Data: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getVitals: $e");
      return null;
    }
  }

  // Discharge API
  static Future<Map<String, dynamic>?> getDischargeDetails(
      String admissionID) async {
    try {
      final response = await dio.get('/discharge/$admissionID');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getDischargeDetails: $e");
      return null;
    }
  }

  // Prescription Sheet API
  static Future<Map<String, dynamic>?> getDrugDetails(
      String admissionID) async {
    try {
      print(
          "Sending request to fetch drug details for admissionID: $admissionID");

      // final response = await dio.get('/drug-sheet/$admissionID');
      final response = await dio
          .get('http://localhost:8090/api/prescription-sheet/$admissionID');

      // Check if the response status is OK (200)
      if (response.statusCode == 200) {
        print("Response received from the backend:");
        print("Response data: ${response.data}"); // Print the data to check it
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getDrugDetails: $e");
      return null;
    }
  }

// Drug Sheet API
  static Future<Map<String, dynamic>?> getMedicationRecord(
      String admissionID) async {
    try {
      print(
          "Sending request to fetch drug details for admissionID: $admissionID");

      // final response = await dio.get('/drug-sheet/$admissionID');
      final response =
          await dio.get('http://localhost:8090/api/drug-sheet/$admissionID');

      // Check if the response status is OK (200)
      if (response.statusCode == 200) {
        print("Response received from the backend:");
        print("Response data: ${response.data}"); // Print the data to check it
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getDrugDetails: $e");
      return null;
    }
  }

  // Consultation Sheet API
  static Future<Map<String, dynamic>?> getConsultationSheet(
      String admissionID) async {
    try {
      final response = await dio.get('/consultation-sheet/$admissionID');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        return null;
      }
    } catch (e) {
      print("Exception in getConsultationSheet: $e");
      return null;
    }
  }

  // progress report
  static Future<Map<String, dynamic>?> getProgressReport(
      String admissionID) async {
    try {
      final response = await dio.get('/progress/$admissionID');
      print("Progress response: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        print("Progress report data: $data");

        if (data is List) {
          // If the response is a List, wrap it in a Map
          return {"data": data};
        } else if (data is Map<String, dynamic>) {
          // If the response is already a Map, return as is
          return data;
        } else {
          print("Unexpected response format: $data");
          return null;
        }
      } else {
        print("Failed to fetch progress report. Response: ${response.data}");
        return null;
      }
    } catch (e) {
      print("Error fetching progress report: $e");
      return null;
    }
  }

//Disposal Status  API
  static Future<bool> updateDisposalStatus(
      String admissionID, String status) async {
    try {
      final response = await dio.put(
        '/disposal/$admissionID',
        data: {
          'Disposal_status': status,
        },
      );

      print("Update disposal response: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print("Failed to update disposal status. Response: ${response.data}");
        return false;
      }
    } catch (e) {
      print("Error updating disposal status: $e");
      return false;
    }
  }
//Bed Occupied Status API

  static Future<bool> updateBedOccupiedStatus({
    required String bedNo,
    required String wardNo,
    required int isOccupied,
  }) async {
    try {
      final response = await dio.put(
        '/bed-occupied-status', // Adjust endpoint path as needed
        data: {
          'Bed_no': bedNo,
          'Ward_no': wardNo,
          'is_occupied': 0,
        },
      );

      print("Update bed status response: ${response.data}");

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404) {
        return true;
      } else {
        print("Failed to update bed status. Response: ${response.data}");
        return false;
      }
    } catch (e) {
      print("Error updating bed status: $e");
      return false;
    }
  }

// Upload to Cloud Status API
  static Future<bool> updateUploadToCloudStatus({
    required String admissionNo,
    required bool uploadedToCloud,
  }) async {
    try {
      final response = await dio.put(
        '/upload-to-cloud-status',
        data: {
          'Admission_no': admissionNo,
          'Uploaded_to_cloud': uploadedToCloud,
        },
      );

      print("Update upload status response: ${response.data}");

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404) {
        return true;
      } else {
        print("Failed to update upload status. Response: ${response.data}");
        return false;
      }
    } catch (e) {
      print("Error updating upload status: $e");
      return false;
    }
  }
}
