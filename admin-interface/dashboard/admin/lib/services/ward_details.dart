import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:admin/services/network_client.dart';

class WardService {
  static final dio = NetworkClient.dio;
  static final cookieJar = NetworkClient.cookieJar;

  static Future<Map<String, String>> fetchWardData() async {
    try {
      final response = await dio.get('/ward/');
      print("Sending GET to ${dio.options.baseUrl}/ward/");

      if (response.statusCode == 200) {
        var decodedResponse = response.data;
        print("Raw API Response: ${response.data}");

        if (decodedResponse is Map && decodedResponse.containsKey("data")) {
          List<dynamic> wardData = decodedResponse["data"];

          Map<String, String> wardMap = {
            for (var ward in wardData)
              ward["Ward_name"].toString(): ward["Ward_no"].toString()
          };

          return wardMap;
        } else {
          print("Invalid API Response Structure!");
          return {};
        }
      } else {
        print("API Error: Status Code ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("Exception while fetching ward names: $e");
      return {};
    }
  }
}
