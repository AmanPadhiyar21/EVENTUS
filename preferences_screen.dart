import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PreferencesScreen extends StatefulWidget {
  final String email;
  const PreferencesScreen({required this.email, Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  List<String> selectedInterests = [];
  String selectedCity = "";
  String selectedCollege = "";

  final List<String> cities = [
    "Ahmedabad",
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Rajkot",
    "Porbandar",
    "Pune",
    "Udaipur"
  ];

  final List<String> interests = [
    "Sports",
    "Tech",
    "Music",
    "Art",
    "Cultural",
    "Adventure",
    "Theatre",
    "Politics",
    "GeoPolitics",
    "Economy"
  ];

  final Map<String, List<String>> collegesByCity = {
    "Ahmedabad": [
      "IIT Ahmedabad",
      "Nirma University",
      "CEPT University",
      "INDUS University"
    ],
    "Mumbai": ["IIT Bombay", "St. Xavier's College"],
    "Delhi": ["DU", "NSUT"],
    "Bangalore": ["IIT Bangalore", "BMS College", "RV College"],
  };

  bool isLoading = false;

  Future<void> savePreferences() async {
    if (selectedCity.isEmpty || selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select a city and at least one interest")),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await ApiService.updatePreferences(
      widget.email,
      selectedCity,
      selectedInterests,
      selectedCollege,
    );

    setState(() => isLoading = false);

    if (success) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("userEmail", widget.email);
      await prefs.setString("selectedCity", selectedCity);
      await prefs.setStringList("selectedInterests", selectedInterests);
      await prefs.setString("selectedCollege", selectedCollege);

      int userId = prefs.getInt("userId") ?? 0;
      String role = prefs.getString("userRole") ?? "user";

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userId: userId,
            email: widget.email,
            selectedCity: selectedCity,
            interests: selectedInterests,
            userRole: role,
            selectedCollege: selectedCollege,
          ),
        ),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to save preferences")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87, // Dark background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A), // Dark grey card
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Your Preferences",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50), // Green accent
                  ),
                ),
                const SizedBox(height: 20),

                // City Dropdown
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select City",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCity.isEmpty ? null : selectedCity,
                    hint: const Text(
                      "Choose City",
                      style: TextStyle(color: Colors.white70),
                    ),
                    dropdownColor: const Color(0xFF2A2A2A),
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCity = value;
                          selectedCollege = "";
                        });
                      }
                    },
                    items: cities
                        .map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(
                        city,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // College Dropdown
                if (selectedCity.isNotEmpty &&
                    collegesByCity[selectedCity] != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select College (Optional)",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCollege.isEmpty ? null : selectedCollege,
                      hint: const Text(
                        "Choose College",
                        style: TextStyle(color: Colors.white70),
                      ),
                      dropdownColor: const Color(0xFF2A2A2A),
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCollege = value);
                        }
                      },
                      items: collegesByCity[selectedCity]!
                          .map((college) => DropdownMenuItem(
                        value: college,
                        child: Text(
                          college,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Interests
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Interests",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.map((interest) {
                    final isSelected = selectedInterests.contains(interest);
                    return ChoiceChip(
                      label: Text(
                        interest,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF4CAF50),
                      backgroundColor: const Color(0xFF3A3A3A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedInterests.add(interest);
                          } else {
                            selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // Save Button
                isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF4CAF50))
                    : ElevatedButton(
                  onPressed: savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save Preferences",
                    style: TextStyle(fontSize: 16),
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
