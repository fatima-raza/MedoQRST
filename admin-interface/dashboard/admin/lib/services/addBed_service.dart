import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:admin/services/network_client.dart';

class AddbedService {
  static final dio = NetworkClient.dio;
  static final cookieJar = NetworkClient.cookieJar;

//   static Future<Map<String, dynamic>?> generateQRCode(
//     String wardNo, bool isSingleBed, int? selectedBedCount, [int? bedNo]) async {
//   print("generateQRCode called");

//   try {
//     if (wardNo.isEmpty) {
//       print("Ward number is empty. Cannot proceed.");
//       return null;
//     }

//     // Check for add new bed mode
//     if (bedNo == null) {
//       if ((selectedBedCount == null || selectedBedCount < 2 || selectedBedCount > 20) && !isSingleBed) {
//         print("Invalid bed count. Must be between 2 and 20.");
//         return null;
//       }

//       print("Add New Bed Mode:");
//       print("   Ward No: $wardNo");
//       print("   Bed Count: $selectedBedCount");

//       final response = await dio.post(
//         "/generateQR/$wardNo",
//         data: {
//           "isSingleBed": isSingleBed,
//           "selectedBedCount": selectedBedCount,
//         },
//       );

//       if (response.statusCode == 201) {
//         print("Response: ${response.data}");
//         return response.data;
//       } else {
//         print("❌ Failed to generate new QR: ${response.data}");
//         return null;
//       }
//     }

//    else {
//   print("Regenerate QR for Existing Bed Mode:");
//   print("   Ward No: $wardNo");
//   print("   Bed No: $bedNo");

//   try {
//     final response = await dio.post(
//       "/regenerateQR/$wardNo/$bedNo",
//       data: {}, // optional body
//     );

//     if (response.statusCode == 200) {
//       print("✅ Regenerated QR: ${response.data}");
//       return response.data;
//     } else if (response.statusCode == 404) {
//       final errorMessage = "Bed no $bedNo does not exist in the ward $wardNo";
//       print("❌ $errorMessage");

//       // ✅ Return meaningful error object instead of null
//       return {
//         "error": true,
//         "message": errorMessage
//       };
//     } else {
//       final genericError = "Failed to regenerate QR: ${response.data}";
//       print("❌ $genericError");

//       // ✅ Return generic error object
//       return {
//         "error": true,
//         "message": genericError
//       };
//     }
//   } on DioError catch (e) {
//     final serverMessage = e.response?.data['message'] ??
//         "Internal server error while regenerating QR";

//     print("❌ DioError: $serverMessage");

//     // ✅ Return Dio error message
//     return {
//       "error": true,
//       "message": serverMessage
//     };
//   } catch (e) {
//     print("❌ Unexpected error: $e");

//     // ✅ Return fallback error object
//     return {
//       "error": true,
//       "message": "Unexpected error occurred. Please try again."
//     };
//   }
// }

//   }}

  static Future<Map<String, dynamic>?> generateQRCode(
      String wardNo, bool isSingleBed, int? selectedBedCount,
      [int? bedNo]) async {
    print("generateQRCode called");

    if (wardNo.isEmpty) {
      print("Ward number is empty. Cannot proceed.");
      return null;
    }

    // Check for add new bed mode
    if (bedNo == null) {
      if ((selectedBedCount == null ||
              selectedBedCount < 2 ||
              selectedBedCount > 20) &&
          !isSingleBed) {
        print("Invalid bed count. Must be between 2 and 20.");
        return null;
      }

      print("Add New Bed Mode:");
      print("   Ward No: $wardNo");
      print("   Bed Count: $selectedBedCount");

      try {
        final response = await dio.post(
          "/generateQR/$wardNo",
          data: {
            "isSingleBed": isSingleBed,
            "selectedBedCount": selectedBedCount,
          },
        );

        if (response.statusCode == 201) {
          print("Response: ${response.data}");
          return response.data;
        } else {
          print("❌ Failed to generate new QR: ${response.data}");
          return null;
        }
      } catch (e) {
        print("❌ Exception while generating new QR: $e");
        return {
          "error": true,
          "message": "An error occurred while generating QR: $e"
        };
      }
    } else {
      print("Regenerate QR for Existing Bed Mode:");
      print("   Ward No: $wardNo");
      print("   Bed No: $bedNo");

      try {
        final response = await dio.post(
          "/regenerateQR/$wardNo/$bedNo",
          data: {}, // optional body
        );

        if (response.statusCode == 200) {
          print("✅ Regenerated QR: ${response.data}");
          return response.data;
        } else if (response.statusCode == 404) {
          final errorMessage =
              "Bed no $bedNo does not exist in the ward $wardNo";
          print("❌ $errorMessage");

          return {"error": true, "message": errorMessage};
        } else {
          final genericError = "Failed to regenerate QR: ${response.data}";
          print("❌ $genericError");

          return {"error": true, "message": genericError};
        }
      } on DioError catch (e) {
        final serverMessage = e.response?.data['message'] ??
            "Internal server error while regenerating QR";
        print("❌ DioError: $serverMessage");

        return {"error": true, "message": serverMessage};
      } catch (e) {
        print("❌ Unexpected error: $e");

        return {
          "error": true,
          "message": "Unexpected error occurred. Please try again."
        };
      }
    }
  }
}







///final
 // Regenerate QR for existing bed
    // else {
    //   print("Regenerate QR for Existing Bed Mode:");
    //   print("   Ward No: $wardNo");
    //   print("   Bed No: $bedNo");

    //   final response = await dio.post(
    //     "/regenerateQR/$wardNo/$bedNo",
    //     data: {}, // optional body
    //   );

    //   if (response.statusCode == 200) {
    //     print("✅ Regenerated QR: ${response.data}");
    //     return response.data;
    //   } else {
    //     print("❌ Failed to regenerate QR: ${response.data}");
    //     return null;
    //   }
    // }
     // on DioException catch (e) {
  //   print("Dio error: ${e.response?.data ?? e.message}");
  //   return null;
  // } catch (e) {
  //   print("General error: $e");
  //   return null;
  // }