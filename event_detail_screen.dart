import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("${event.category} @ ${event.location}"),
            const SizedBox(height: 8),
            Text("${event.city}${event.college != null ? " - ${event.college}" : ""}"),
            const SizedBox(height: 8),
            Text("Date: ${event.date}"),
            const SizedBox(height: 16),
            Text(event.description),
            const Spacer(),
            if (event.registrationLink != null && event.registrationLink!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => launchUrl(Uri.parse(event.registrationLink!),
                      mode: LaunchMode.externalApplication),
                  child: const Text("Register"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
