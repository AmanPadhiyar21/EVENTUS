import 'package:flutter/material.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  final int userId;
  const SubscriptionScreen({super.key, required this.userId});

  void _subscribe(BuildContext context, String plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(userId: userId, plan: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentGreen = Color(0xFF00E676); // neon green
    const Color cardDark = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E), // slightly lighter than black
        centerTitle: true,
        title: const Text(
          "Upgrade to Pro 🚀",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // center vertically
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Unlock Pro Features",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "✨ Create unlimited events\n"
                      "✨ Boost your visibility\n"
                      "✨ Access premium analytics",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),

                // Monthly Plan
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: cardDark,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: accentGreen.withOpacity(0.5), width: 1.2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    leading: const Icon(Icons.calendar_month, color: Colors.greenAccent, size: 36),
                    title: const Text(
                      "Monthly Plan",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      "₹10 / month",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _subscribe(context, "monthly"),
                      child: const Text("Subscribe"),
                    ),
                  ),
                ),

                // Yearly Plan
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: cardDark,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: accentGreen.withOpacity(0.5), width: 1.2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    leading: const Icon(Icons.workspace_premium, color: Colors.amber, size: 36),
                    title: const Text(
                      "Yearly Plan",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      "₹100 / year",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _subscribe(context, "yearly"),
                      child: const Text("Subscribe"),
                    ),
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
