import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class NetworkClient {
  static const String baseUrl = "http://localhost:8090/api";
  static const String cookieDomain = "http://localhost:8090";

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => status! < 500,
  ));

  static PersistCookieJar? cookieJar;
  static bool _interceptorsAdded = false;

  // Method to initialize the cookie jar with persistence
  static Future<void> initializeCookies(String cookiePath) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      print("App document directory: ${appDocDir.path}");

      if (cookiePath.isEmpty) {
        print("Error: cookiePath is empty");
        return;
      }

      // Log the full path we are creating
      final fullPath = path.join(appDocDir.path, cookiePath);
      print("Full cookie path: $fullPath");

      // Initialize cookie jar with the computed path
      cookieJar = PersistCookieJar(
        storage: FileStorage(fullPath),
        ignoreExpires: true, // You can decide to ignore expiry or not
      );
      dio.interceptors.add(CookieManager(cookieJar!));

      // 🔍 Print saved cookie files (for debugging)
      final cookieFiles = Directory(fullPath).listSync();
      for (var file in cookieFiles) {
        print("Saved cookie file: ${file.path}");
      }
    } catch (e) {
      print("Error initializing cookies: $e");
    }
  }

  static void setupInterceptors(Function onSessionExpired) {
    if (_interceptorsAdded) return; // Prevent multiple interceptor additions
    _interceptorsAdded = true;

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies = await cookieJar?.loadForRequest(options.uri);
        print("\n=== Sending Request ===");
        print("URL: ${options.baseUrl}${options.path}");
        print("Method: ${options.method}");
        print("Headers: ${options.headers}");

        if (cookies?.isEmpty ?? true) {
          print("No cookies being sent.");
        } else {
          print("Cookies being sent: $cookies");
        }

        return handler.next(options);
      },
      onResponse: (response, handler) async {
        print("\n=== Received Response ===");
        print("URL: ${response.requestOptions.uri}");
        print("Status: ${response.statusCode}");
        print("Headers: ${response.headers}");
        print("Cookies: ${response.headers['set-cookie']}");
        return handler.next(response);
      },
      onError: (DioError error, handler) async {
        print("\n=== Error Occurred ===");
        print("URL: ${error.requestOptions.uri}");
        print("Status: ${error.response?.statusCode}");
        print("Error: ${error.message}");

        if (error.response?.statusCode == 401) {
          print("Session expired - clearing cookies and redirecting to login");
          await cookieJar?.deleteAll();
          onSessionExpired();
        }

        return handler.next(error);
      },
    ));
  }

  // Method to check if the session is valid
  static Future<bool> checkSession() async {
    try {
      print("Loading cookies for session check...");
      if (cookieJar == null) {
        print("Cookie jar is not initialized!");
        return false; // Cookie jar is not initialized yet
      }

      final cookies = await cookieJar!.loadForRequest(Uri.parse(cookieDomain));
      print("Cookies in jar: $cookies");

      if (cookies.isEmpty) {
        print("no cookies found");
        return false; // No cookies, user is not logged in
      }

      // Optionally, you can make an API call to verify session validity here
      print("Validating session with server...");
      final response = await dio.get(
          "/auth/status"); // Assuming /auth/status is your session check endpoint
      return response.statusCode == 200;
    } catch (e) {
      print("Session check failed: $e");
      return false;
    }
  }

  static Future<void> clearCookies() async {
    await cookieJar?.deleteAll();
  }
}
