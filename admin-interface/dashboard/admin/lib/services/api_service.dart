import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:admin/services/network_client.dart';

class ApiService {
  static final dio = NetworkClient.dio;
  static final cookieJar = NetworkClient.cookieJar;

  // ------------------------ AUTHORIZATION API -----------------------
  // Function to authenticate an admin
  Future<bool> adminLogin(String username, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        // Assuming the API returns a success status with a 200 code
        return true;
      } else {
        print("Login failed: ${response.data}");
        return false;
      }
    } catch (error) {
      print("Error logging in: $error");
      return false;
    }
  }

  // ------------------------ CHANGE ADMIN PASSWORD API ------------------------
  Future<Map<String, dynamic>> changeAdminPassword(
      String oldPassword, String newPassword) async {
    try {
      print("Sending password change request...");

      final response = await dio.post(
        "/admin/change-password",
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 200) {
        print("Password changed successfully.");
        return {'success': true, 'message': 'Password changed successfully'};
      } else {
        final errorMsg = response.data['error'] ?? "Failed to change password";
        print("Password change failed: $errorMsg");
        return {'success': false, 'error': errorMsg};
      }
    } catch (error) {
      print("Error during password change: $error");
      return {
        'success': false,
        'error': error.toString().replaceAll('Exception: ', '')
      };
    }
  }

  // ------------------------ FORGOT PASSWORD API -----------------------
  Future<Map<String, dynamic>> sendForgotPasswordEmail(String email) async {
    try {
      print("Sending forgot password email...");

      final response = await dio.post(
        "/admin/forgot-password",
        data: {'email': email},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      // 👇 Inspect actual success flag from backend
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Unexpected error'
        };
      }
    } on DioException catch (dioError) {
      final errorMsg = dioError.response?.data['error'] ??
          dioError.message ??
          "Something went wrong";

      print("Dio Error: $errorMsg");

      return {'success': false, 'error': errorMsg};
    } catch (error) {
      print("Unexpected error during forgot password: $error");
      return {
        'success': false,
        'error': error.toString().replaceAll('Exception: ', '')
      };
    }
  }

  // ------------------------ REGISTRATION API ------------------------
  // Function to register a new patient
  Future<String?> createPatient(Map<String, dynamic> patientData) async {
    try {
      print("Request Body: ${jsonEncode(patientData)}");
      print("Sending request to: ${dio.options.baseUrl}/patient/create");

      final response = await dio.post(
        "/patient/create",
        data: patientData,
      );

      // additional
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 201) {
        return response.data['patientId']; // Return the PatientID
      } else {
        return null; // Handle errors properly
      }
    } catch (error) {
      print("Error: $error");
      return null;
    }
  }

  // Function to register a new doctor
  Future<String?> createDoctor(Map<String, dynamic> doctorData) async {
    // Debugging logs
    print("Sending request to: ${dio.options.baseUrl}/doctor/create");
    print("Request Body: ${jsonEncode(doctorData)}");

    try {
      final response = await dio.post(
        "/doctor/create",
        data: doctorData,
      );

      // Debugging logs
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 201) {
        return response.data['userId']; // Assuming the API returns 'doctorId'
      } else {
        return null; // Handle errors properly
      }
    } catch (error) {
      print("Error: $error");
      return null;
    }
  }

  // Function to register a new nurse
  Future<String?> createNurse(Map<String, dynamic> nurseData) async {
    // Debugging logs
    print("Sending request to: ${dio.options.baseUrl}/nurse/create");
    print("Request Body: ${jsonEncode(nurseData)}");

    try {
      final response = await dio.post(
        "/nurse/create",
        data: nurseData,
      );

      // Debugging logs
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 201) {
        return response.data['userId']; // Assuming the API returns 'nurseId'
      } else {
        return null; // Handle errors properly
      }
    } catch (error) {
      print("Error: $error");
      return null;
    }
  }

  // Function to update an existing patient
  Future<bool> updatePatient(
      String patientId, Map<String, dynamic> patientData) async {
    print(
        "Sending request to: ${dio.options.baseUrl}/patient/update/$patientId");
    print("Request Body: ${jsonEncode(patientData)}");

    try {
      final response = await dio.put(
        "/patient/update/$patientId",
        data: patientData,
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 200) {
        return true; // Successfully updated
      } else {
        return false; // Update failed
      }
    } catch (error) {
      print("Error updating patient: $error");
      return false;
    }
  }

  // ------------------------------- ADMISSION API -----------------------------
  // function to store admission info
  Future<String?> storeAdmissionInfo(Map<String, dynamic> admissionData) async {
    print("Request Body: ${jsonEncode(admissionData)}");
    print("Sending request to: ${dio.options.baseUrl}/admission/create");

    if (admissionData.containsKey('PatientID')) {
      admissionData['patientId'] = admissionData['PatientID'];
      admissionData.remove('PatientID');
    }
    if (admissionData.containsKey('Admitted_under_care_of')) {
      admissionData['admittedUnderCareOf'] =
          admissionData['Admitted_under_care_of'];
      admissionData.remove('Admitted_under_care_of');
    }

    if (admissionData['patientId'] == null ||
        admissionData['patientId'].isEmpty) {
      print("ERROR: patientId is missing!");
      return null;
    }
    if (admissionData['admittedUnderCareOf'] == null ||
        admissionData['admittedUnderCareOf'].isEmpty) {
      print("ERROR: doctorId is missing!");
      return null;
    }

    try {
      final response = await dio.post(
        "/admission/create",
        data: admissionData,
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 201) {
        return response
            .data['admissionNo']; // Return the auto-generated Admission Number
      } else {
        print("Error: Unexpected response: ${response.data}");
        return null;
      }
    } catch (error) {
      print("Error submitting admission info: $error");
      return null;
    }
  }

  // function to store emergency contact details
  Future<Map<String, dynamic>?> storeEmergencyContactInfo(
      Map<String, dynamic> contactData) async {
    // Debugging - identical to your pattern
    print(
        "Sending request to: ${dio.options.baseUrl}/emergency-contact/create");
    print("Request Body: ${jsonEncode(contactData)}");

    try {
      final response = await dio.post(
        "/emergency-contact/create",
        data: contactData,
      );

      // Debugging - identical to your pattern
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (error) {
      print(
          "Error submitting emergency contact info: $error"); // Same error logging
    }
    return null;
  }

  // ------------------------------- WARD API ----------------------------------
  // Fetch all wards
  Future<List<Map<String, dynamic>>?> getAllWards() async {
    print("Sending request to: ${dio.options.baseUrl}/ward/read");

    try {
      final response = await dio.get("/ward/read");

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;

        final wards = (data['wards'] as List<dynamic>).map((ward) {
          return {
            'wardName':
                ward['Ward_name'] ?? 'Unknown Ward', // Default value for nulls
            'wardNo':
                ward['Ward_no'] ?? 'Unknown No', // Default value for nulls
          };
        }).toList();
        return wards;
        // return List<Map<String, dynamic>>.from(data['wards']);
      } else {
        print("Failed to fetch wards. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (error) {
      print("Error fetching wards: $error");
      return null;
    }
  }

  // Function to create a new ward with QR code
  Future<Map<String, dynamic>?> createWard(String wardName) async {
    try {
      final response = await dio.post(
        "/ward/create",
        data: {'wardName': wardName},
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 201) {
        return response.data; // returns full json
      } else {
        print("Ward creation failed: ${response.data['message']}");
        return null;
      }
    } catch (error) {
      print("Error creating ward: $error");
      return null;
    }
  }

  Future<Map<String, dynamic>> regenerateQRForWard(String wardName) async {
    // print("Sending QR regeneration request for ward: $wardName");
    print("🛠 regenerateQRForWard CALLED with ward: $wardName");

    try {
      final response = await dio.post(
        "/ward/update",
        data: {'wardName': wardName},
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Update failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  // ------------------------ BED API ------------------------
  // Fetch available beds by ward number
  Future<Map<String, dynamic>?> getAvailableBeds(String wardNo) async {
    print(
        "Sending request to: ${dio.options.baseUrl}/bed/$wardNo/available-beds");
    try {
      final response = await dio.get("/bed/$wardNo/available-beds");

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        print("Failed to fetch beds. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching beds: $e");
      return null;
    }
  }

  // --------------------------- DOCTOR API ---------------------------
  Future<List<Map<String, dynamic>>> fetchDoctors(String query) async {
    print(
        "Sending request to: ${dio.options.baseUrl}/doctor/read?search=$query");

    try {
      final response = await dio.get("/doctor/read?search=$query");

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data); // Convert to List of Maps
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching doctors: $e");
      return [];
    }
  }

  // ------------------------ PATIENT IDENTIFICATION API -----------------------
  Future<Map<String, dynamic>?> checkExistingPatient(String identifier) async {
    print(
        "Sending request to: ${dio.options.baseUrl}/patient/search/$identifier");
    try {
      final response = await dio.get("/patient/search/$identifier");

      if (response.statusCode == 200) {
        return {
          'found': true,
          'data': response.data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'found': false,
          'message': 'No previous record found.',
        };
      } else {
        return {
          'found': false,
          'message':
              'Invalid identifier format. Provide a valid Patient ID or CNIC.'
        };
      }
    } catch (e) {
      print("Error searching patient: $e");
      return {'found': false, 'message': 'Internal Server Error'};
    }
  }

  // --------------------------- DEPARTMENT API ---------------------------
  // Function to fetch departments
  Future<List<Map<String, dynamic>>> fetchDepartments(String query) async {
    print("Sending request to: ${dio.options.baseUrl}/department/read");
    try {
      final response = await dio.get("/department/read");

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> departments =
            List<Map<String, dynamic>>.from(response.data);

        // Filter departments based on the query if it's not empty
        if (query.isNotEmpty) {
          departments = departments
              .where((dept) => dept['Department_name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
        }
        return departments;
      } else {
        return [];
      }
    } catch (error) {
      print("Error fetching departments: $error");
      return [];
    }
  }

  // --------------------------- LOGOUT API ---------------------------
  static Future<bool> adminLogout() async {
    try {
      final response = await dio.post('/auth/logout');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Logout failed: ${response.data}');
        return false;
      }
    } catch (error) {
      print('Error logging out: $error');
      return false;
    }
  }
}
