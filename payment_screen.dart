import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_event_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int userId;
  final String plan;

  const PaymentScreen({super.key, required this.userId, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _mockPayment();
  }

  Future<void> _mockPayment() async {
    try {
      final res = await http.post(
        Uri.parse("http://192.168.29.14:5000/api/payment/mock-upgrade"), // emulator
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": widget.userId,
          "plan": widget.plan,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception("Server returned ${res.statusCode}");
      }

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userRole", "pro");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Payment Successful! You are now Pro.")),
        );

        // Navigate to CreateEventScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateEventScreen()),
        );
      } else {
        throw Exception(data["message"] ?? "Upgrade failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Processing Payment")),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
