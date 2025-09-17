import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // ✅ import
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  String city = "";
  List<String> interests = [];
  File? _profileImage; // ✅ to store selected image

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileData(); // refresh when returning
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString("userName") ?? "";
      email = prefs.getString("userEmail") ?? "";
      city = prefs.getString("selectedCity") ?? "Not Selected";
      interests = prefs.getStringList("selectedInterests") ?? [];

      String? imgPath = prefs.getString("profileImage");
      if (imgPath != null && imgPath.isNotEmpty) {
        _profileImage = File(imgPath);
      }
    });

    if (email.isNotEmpty) {
      final prefRes = await ApiService.getPreferences(email);
      if (prefRes["success"] == true && prefRes["preferences"] != null) {
        final newCity = prefRes["preferences"]["city"] ?? "Not Selected";
        final newInterests = List<String>.from(prefRes["preferences"]["interests"] ?? []);

        setState(() {
          city = newCity;
          interests = newInterests;
        });

        await prefs.setString("selectedCity", newCity);
        await prefs.setStringList("selectedInterests", newInterests);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("profileImage", pickedFile.path); // ✅ store path
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.greenAccent)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage, // whole avatar also tappable
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.person, size: 60, color: Colors.greenAccent)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage, // tapping the small + button
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(Icons.add, size: 20, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  name.isNotEmpty ? name : "No Name",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  email.isNotEmpty ? email : "No Email",
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_city, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text("City: $city", style: TextStyle(color: Colors.grey[300], fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Interests:",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.isNotEmpty
                      ? interests.map((e) => Chip(
                    label: Text(e, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.grey[800],
                    side: const BorderSide(color: Colors.greenAccent),
                  )).toList()
                      : [
                    Chip(
                      label: const Text("No interests selected", style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.grey[800],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: Colors.redAccent.withOpacity(0.4),
                    ),
                    child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
