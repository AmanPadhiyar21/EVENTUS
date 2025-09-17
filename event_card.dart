import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onDelete; // Callback to refresh UI after deletion

  const EventCard({super.key, required this.event, this.onDelete});

  Future<void> _deleteEvent(BuildContext context) async {
    bool success = await ApiService.deleteEvent(event.id!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event deleted successfully")),
      );
      if (onDelete != null) onDelete!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete event")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Delete icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEvent(context),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Date & Location
            Text(
              event.date,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              event.location,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Register button
            if (event.registrationLink != null &&
                event.registrationLink!.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  launchUrl(Uri.parse(event.registrationLink!));
                },
                child: const Text("Register"),
              ),
          ],
        ),
      ),
    );
  }
}
