import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/event_model.dart';
import 'dart:io';               // 👈 for File
import 'package:image_picker/image_picker.dart'; // 👈 for picking images


class ApiService {
  // 🔹 Base URLs
  static final String eventsBaseUrl = "http://192.168.29.14:5001";
  static final String authBaseUrl = "http://192.168.29.14:5000";
// Flask Events service

  // ✅ REGISTER

  static Future<Map<String, dynamic>> register(
      String name, String email, String password, {String role = "user"}) async {
    try {
      final res = await http.post(
        Uri.parse("$authBaseUrl/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role,  // ✅ Send role
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "error": "Server not reachable"};
    }
  }


  static Future<Map<String, dynamic>> login(
      String email,
      String password, {
        required String role, // this is Flutter side 'selectedRole'
      }) async {
    try {
      final res = await http.post(
        Uri.parse("$authBaseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "loginAs": role, // ✅ must match backend
        }),
      );

      final data = jsonDecode(res.body);

      return {
        "success": data["success"] ?? false,
        "message": data["message"] ?? "",
        "user": data["user"] ?? {},
      };
    } catch (e) {
      return {"success": false, "error": "Server not reachable"};
    }
  }


  // ✅ GET PREFERENCES
  static Future<Map<String, dynamic>> getPreferences(String email) async {
    try {
      final res = await http.get(
        Uri.parse("$authBaseUrl/api/auth/preferences?email=$email"),
        headers: {"Content-Type": "application/json"},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "error": "Server not reachable"};
    }
  }

  // ✅ UPDATE PREFERENCES
  static Future<bool> updatePreferences(
      String email, String city, List<String> interests, String selectedCollege) async {
    try {
      final res = await http.post(
        Uri.parse("$authBaseUrl/api/auth/preferences"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "city": city,
          "interests": interests,
        }),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("❌ updatePreferences error: $e");
      return false;
    }
  }

  // ✅ FETCH EVENTS
  static Future<List<dynamic>> fetchEvents({
    String? city,
    List<String>? interests,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (interests != null && interests.isNotEmpty) {
        queryParams['interests'] = interests.join(",");
      }

      final uri = Uri.parse("$eventsBaseUrl/api/events")
          .replace(queryParameters: queryParams);

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ✅ LOAD EVENTS
  static Future<bool> loadEvents({String city = "Ahmedabad"}) async {
    try {
      final response = await http.post(
        Uri.parse('$eventsBaseUrl/events/load'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"city": city}),
      );

      if (response.statusCode != 200) {
        print("❌ loadEvents failed: ${response.statusCode} ${response.body}");
      }

      return response.statusCode == 200;
    } catch (e) {
      print("❌ loadEvents error: $e");
      return false;
    }
  }

  // ✅ FETCH FILTERED EVENTS
  static Future<List<EventModel>> fetchFilteredEvents({
    required String city,
    required List<String> interests,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$eventsBaseUrl/api/events/filter'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'city': city,
          'interests': interests,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => EventModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to fetch filtered events: ${response.body}");
      }
    } catch (e) {
      print("❌ fetchFilteredEvents error: $e");
      return [];
    }
  }

  // ✅ USER PROFILE
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final response =
      await http.get(Uri.parse('$authBaseUrl/api/user/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("❌ getUserProfile error: $e");
      return null;
    }
  }

  // ✅ ADD EVENT
  static Future<bool> addEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await http.post(
        Uri.parse('$eventsBaseUrl/api/events/add'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(eventData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("❌ Add Event Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error adding event: $e");
      return false;
    }
  }

  // ✅ DELETE EVENT
  static Future<bool> deleteEvent(int id) async {
    final url = Uri.parse('$eventsBaseUrl/api/events/$id');

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        print("✅ Successfully deleted event with id: $id");
        return true;
      } else {
        print(
            "❌ Delete Event Failed (status ${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error deleting event with id $id: $e");
      return false;
    }
  }

  static Future<bool> markNotInterested(int eventId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$eventsBaseUrl/api/events/$eventId/not-interested'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) return true;
      print("❌ markNotInterested failed: ${response.body}");
      return false;
    } catch (e) {
      print("❌ markNotInterested error: $e");
      return false;
    }
  }

  static Future<bool> rateEvent(int eventId, double rating) async {
    final url = Uri.parse('$eventsBaseUrl/api/events/$eventId/rate');
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rating": rating}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("❌ rateEvent error: $e");
      return false;
    }
  }


  static Future<Map<String, dynamic>?> createPaymentOrder(String email, String plan) async {
    try {
      final res = await http.post(
        Uri.parse("$authBaseUrl/payment/createOrder"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "plan": plan}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Error creating payment order: $e");
    }
    return null;
  }



  // ✅ PRO USER: Upgrade to Pro
  static Future<bool> mockUpgrade(int userId, String plan) async {
    final res = await http.post(
      Uri.parse("$authBaseUrl/api/auth/mock-upgrade"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "plan": plan}),
    );
    final data = jsonDecode(res.body);
    return data["success"] == true;
  }

  // ✅ PRO USER: Check Pro Status
  static Future<Map<String, dynamic>> checkProStatus(String email) async {
    try {
      final response = await http.get(
        Uri.parse("$authBaseUrl/api/auth/pro-status?email=$email"),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": "Server not reachable"};
    }
  }

  static Future<String> sendBoxBotMessage(String message) async {
    final url = Uri.parse("$eventsBaseUrl/api/boxbot");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "No reply from bot.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
  static Future<String?> uploadEventImage(int eventId, File file) async {
    try {
      final uri = Uri.parse("$eventsBaseUrl/api/events/$eventId/upload-image");

      var request = http.MultipartRequest("POST", uri);
      request.files.add(await http.MultipartFile.fromPath("file", file.path)); // correct field name

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final respJson = json.decode(respStr);
        return respJson["imageUrl"]; // ⚡ must match backend key
      } else {
        print("Upload failed: ${response.statusCode}, $respStr");
        return null;
      }
    } catch (e) {
      print("Upload exception: $e");
      return null;
    }
  }






  // 🔹 Event details (to implement later)
  static Future fetchEventDetails(int eventId) async {}
}
