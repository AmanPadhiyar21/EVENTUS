import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully");

    // Debug: check if FLASK_SERVER is loaded
    print("FLASK_SERVER: ${dotenv.env['FLASK_SERVER']}");
  } catch (e) {
    print("⚠️ .env file not found, using default values");
  }

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, dynamic>> checkLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString("userEmail");
      String? city = prefs.getString("selectedCity");
      List<String>? interests = prefs.getStringList("selectedInterests");
      int? userId = prefs.getInt("userId");
      String? role = prefs.getString("userRole");

      return {
        "isLoggedIn": email != null,
        "email": email ?? "",
        "city": city ?? "",
        "interests": interests ?? [],
        "userId": userId ?? 0,
        "role": role ?? "user",
      };
    } catch (e) {
      print("❌ checkLogin error: $e");
      return {
        "isLoggedIn": false,
        "email": "",
        "city": "",
        "interests": [],
        "userId": 0,
        "role": "user",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventus',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Map<String, dynamic>>(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data!["isLoggedIn"] == true) {
            return HomeScreen(
              userId: snapshot.data!["userId"],
              email: snapshot.data!["email"],
              selectedCity: snapshot.data!["city"],
              interests: List<String>.from(snapshot.data!["interests"]),
              userRole: snapshot.data!["role"],
            );
          } else {
            return LoginScreen();
          }
        },
      ),
      routes: {
        "/home": (context) =>  LoginScreen(),
        "/register": (context) => RegisterScreen(),
      },
    );
  }
}
