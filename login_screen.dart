import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'preferences_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;
  String selectedRole = "user"; // default

  Future<void> _login() async {
    setState(() => isLoading = true);

    final res = await ApiService.login(
      emailCtrl.text,
      passCtrl.text,
      role: selectedRole,
    );

    setState(() => isLoading = false);

    if (res["success"] == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userData = res["user"] ?? {};

      final backendRole = userData["role"] ?? "user";

      await prefs.setInt("userId", userData["id"] ?? 0);
      await prefs.setString("userEmail", userData["email"] ?? emailCtrl.text);
      await prefs.setString("userRole", backendRole);

      final prefRes = await ApiService.getPreferences(userData["email"]);
      String city = "";
      List<String> interests = [];

      if (prefRes["success"] == true &&
          prefRes["preferences"] != null &&
          prefRes["preferences"]["city"] != null) {
        city = prefRes["preferences"]["city"];
        interests = List<String>.from(prefRes["preferences"]["interests"] ?? []);
        await prefs.setString("selectedCity", city);
        await prefs.setStringList("selectedInterests", interests);
      }

      if (backendRole == "user" && (city.isEmpty || interests.isEmpty)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PreferencesScreen(email: emailCtrl.text)),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userId: userData["id"] ?? 0,
              email: userData["email"] ?? emailCtrl.text,
              selectedCity: city,
              interests: interests,
              userRole: backendRole,
            ),
          ),
              (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "❌ Login failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 20),
              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login to continue",
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
              const SizedBox(height: 30),

              // Role selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text("User"),
                    selected: selectedRole == "user",
                    onSelected: (val) => setState(() => selectedRole = "user"),
                    selectedColor: Colors.greenAccent,
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: selectedRole == "user" ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text("Pro"),
                    selected: selectedRole == "pro",
                    onSelected: (val) => setState(() => selectedRole = "pro"),
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: selectedRole == "pro" ? Colors.white : Colors.grey[300],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Email field
              TextField(
                controller: emailCtrl,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Login button
              isLoading
                  ? CircularProgressIndicator(color: Colors.blueAccent)
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    selectedRole == "user" ? "Login as User" : "Login as Pro",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Register navigation
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                ),
                child: Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
