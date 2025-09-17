import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String description = '';
  String city = '';
  String college = '';
  String registrationLink = '';
  String category = '';
  String? imageUrl;
  String address = '';
  String pincode = '';

  DateTime? _eventDate;
  DateTime? _expiryDateTime;
  bool _isLoading = false;

  File? _pickedImage;

  final List<String> categories = [
    "Cultural", "Sports", "Tech", "Workshop", "Music",
    "Art", "Adventure", "Theatre", "Politics", "GeoPolitics", "Economy"
  ];

  final Map<String, List<String>> collegesByCity = {
    "Ahmedabad": ["Nirma University", "LD College", "IIM Ahmedabad", "INDUS University"],
    "Mumbai": ["IIT Bombay", "St. Xavier's", "Mumbai University"],
    "Delhi": ["Delhi University", "IIT Delhi", "JNU"],
    "Bangalore": ["IISc", "Christ University", "RV College"],
    "Rajkot": ["Marwadi University", "RK University"],
    "Porbandar": ["Porbandar College of Arts", "Porbandar Science College"],
    "Pune": ["SPPU", "MIT WPU", "Symbiosis"],
    "Udaipur": ["MLS University", "IIM Udaipur"],
  };

  final List<String> cities = [
    "Ahmedabad", "Mumbai", "Delhi", "Bangalore",
    "Rajkot", "Porbandar", "Pune", "Udaipur"
  ];

  // ==================== PICK DATE ====================
  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.greenAccent,
            onPrimary: Colors.black,
            surface: Colors.black87,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: Colors.black87,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _eventDate = picked;
        _expiryDateTime = picked.copyWith(hour: 23, minute: 59, second: 59);
      });
    }
  }

  // ==================== PICK TIME ====================
  Future<void> _pickExpiryTime() async {
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Pick Event Date first")),
      );
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiryDateTime ?? DateTime.now()),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.greenAccent,
            onPrimary: Colors.white,
            surface: Colors.black87,
            onSurface: Colors.white,
          ),
          timePickerTheme: const TimePickerThemeData(
            dialHandColor: Colors.greenAccent,
            hourMinuteTextColor: Colors.white,
            dayPeriodTextColor: Colors.white70,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime != null) {
      setState(() {
        _expiryDateTime = DateTime(
          _eventDate!.year,
          _eventDate!.month,
          _eventDate!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  // ==================== PICK IMAGE ====================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  // ==================== ADD EVENT ====================
  // ==================== ADD EVENT ====================
  Future<void> addEvent() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    String? uploadedImageUrl;
    if (_pickedImage != null) {
      // Upload image and get server URL
      uploadedImageUrl = await ApiService.uploadEventImage(0, _pickedImage!);
      if (uploadedImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to upload image")),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final eventData = {
      "id": 0,
      "title": title,
      "description": description,
      "city": city,
      "college": college.isNotEmpty ? college : null,
      "address": address.isNotEmpty ? address : null,
      "pincode": pincode.isNotEmpty ? pincode : null,
      "date": _eventDate != null ? DateFormat("yyyy-MM-dd").format(_eventDate!) : "",
      "category": category,
      "registrationLink": registrationLink.isNotEmpty ? registrationLink : null,
      "location": city,
      "creatorId": 0,
      "rating": 0.0,
      "imageUrl": uploadedImageUrl, // ✅ Use uploaded URL
      "expiry": _expiryDateTime != null
          ? DateFormat("yyyy-MM-dd HH:mm:ss").format(_expiryDateTime!)
          : null,
    };

    final success = await ApiService.addEvent(eventData);
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, eventData); // ✅ Return full event with server image URL
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to add event")),
      );
    }
  }

  // ==================== INPUT DECORATION ====================
  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.black87,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.greenAccent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
    ),
  );

  // ==================== BUTTON ====================
  Widget _buildButton(String text, VoidCallback onPressed) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.greenAccent, Colors.white], // green → white
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.greenAccent.withOpacity(0.4),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black, // text color
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Create Event", style: TextStyle(color: Colors.greenAccent)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // IMAGE PICKER
                  InkWell(
                    onTap: _pickImage,
                    child: _pickedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _pickedImage!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_a_photo, color: Colors.greenAccent, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TITLE
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Title"),
                    onSaved: (val) => title = val!.trim(),
                    validator: (val) => val == null || val.isEmpty ? "Enter title" : null,
                  ),
                  const SizedBox(height: 16),

                  // DESCRIPTION
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Description"),
                    maxLines: 3,
                    onSaved: (val) => description = val!.trim(),
                    validator: (val) => val == null || val.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 16),

                  // CITY
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black87,
                    decoration: _inputDecoration("City"),
                    value: city.isNotEmpty ? city : null,
                    items: cities.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) => setState(() {
                      city = val ?? '';
                      college = '';
                    }),
                    validator: (val) => val == null || val.isEmpty ? "Select a city" : null,
                  ),
                  const SizedBox(height: 16),

                  // COLLEGE
                  if (city.isNotEmpty && collegesByCity.containsKey(city))
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black87,
                      decoration: _inputDecoration("College (optional)"),
                      value: college.isNotEmpty ? college : null,
                      items: collegesByCity[city]!.map((col) => DropdownMenuItem(
                        value: col,
                        child: Text(col, style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setState(() => college = val ?? ''),
                    ),
                  const SizedBox(height: 16),

                  // ADDRESS
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Address (optional)"),
                    onSaved: (val) => address = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),

                  // PINCODE
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Pincode (optional)"),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => pincode = val?.trim() ?? '',
                    validator: (val) {
                      if (val != null && val.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(val)) {
                        return "Enter valid 6-digit pincode";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // EVENT DATE
                  _buildButton(
                    _eventDate == null
                        ? "📅 Pick Event Date"
                        : "📅 ${DateFormat("dd MMM yyyy").format(_eventDate!)}",
                    _pickEventDate,
                  ),
                  const SizedBox(height: 16),

                  // CATEGORY
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black87,
                    decoration: _inputDecoration("Category"),
                    value: category.isNotEmpty ? category : null,
                    items: categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) => setState(() => category = val ?? ''),
                    validator: (val) => val == null || val.isEmpty ? "Select a category" : null,
                  ),
                  const SizedBox(height: 16),

                  // REGISTRATION LINK
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Registration Link (optional)"),
                    onSaved: (val) => registrationLink = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),

                  // EXPIRY TIME
                  _buildButton(
                    _expiryDateTime == null
                        ? "⏰ Pick Expiry Time"
                        : "⏰ ${DateFormat("dd MMM yyyy, hh:mm a").format(_expiryDateTime!)}",
                    _pickExpiryTime,
                  ),
                  const SizedBox(height: 24),

                  // ADD EVENT BUTTON
                  _buildButton(
                    _isLoading ? "Loading..." : "✅ Add Event",
                    _isLoading ? () {} : addEvent,
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: CircularProgressIndicator(color: Colors.greenAccent),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
