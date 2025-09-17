import 'package:evntus/screens/payment_screen.dart';
import 'package:evntus/screens/subcription_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import '../models/event_model.dart';
import 'create_event_screen.dart';
import 'boxbot_chat_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String selectedCity;
  final List<String> interests;
  final String userRole;
  final int userId;
  final String selectedCollege;

  const HomeScreen({
    required this.email,
    required this.selectedCity,
    required this.interests,
    required this.userRole,
    required this.userId,
    this.selectedCollege = "",
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EventModel> events = [];
  List<EventModel> filteredEvents = [];
  DateTime? lastBackPressTime;
  late String currentRole;

  String searchQuery = "";
  String selectedCategory = "All";
  String selectedCity = "";
  String selectedCollege = "";

  final List<String> categories = [
    "All", "Sports", "Tech", "Music", "Art", "Cultural", "Adventure",
    "Theatre", "Politics", "GeoPolitics", "Economy"
  ];

  final List<String> cities = [
    "Ahmedabad", "Mumbai", "Delhi", "Bangalore", "Rajkot", "Porbandar", "Pune", "Udaipur"
  ];

  final Map<String, List<String>> cityColleges = {
    "Ahmedabad": ["IIT Ahmedabad", "Nirma University", "Gujarat University", "INDUS University"],
    "Mumbai": ["IIT Bombay", "NMIMS", "University of Mumbai"],
    "Delhi": ["DTU", "JNU", "University of Delhi"],
    "Bangalore": ["IISc", "Bangalore University", "RV College"],
  };

  bool isLoading = true;

  // Colors & Gradient
  final Color bgBlack = Colors.grey[900]!;
  final Color cardBlack = Colors.grey[850]!;
  final LinearGradient accentGradient = const LinearGradient(
    colors: [Color(0xFF69F0AE), Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  final Color accentGreen = const Color(0xFF69F0AE);
  final Color accentGreenLight = const Color(0xFFB9F6CA);
  final Color textLightGrey = Colors.grey[300]!;

  @override
  void initState() {
    super.initState();
    currentRole = widget.userRole;
    selectedCity = widget.selectedCity;
    selectedCollege = widget.selectedCollege;
    _initHome();
  }

  Future<void> _initHome() async {
    try {
      await ApiService.loadEvents(city: selectedCity);
      final fetchedEventsRaw = await ApiService.fetchEvents(
        city: selectedCity,
        interests: widget.interests,
      );
      final fetchedEvents = fetchedEventsRaw
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        final allEvents = [
          ...fetchedEvents,
          ...events.where((e) => e.city == selectedCity && !fetchedEvents.any((f) => f.id == e.id))
        ];
        events = allEvents;
        filteredEvents = List.from(events);
        isLoading = false;
      });

      filterEventsLocally();
    } catch (e) {
      print("❌ HomeScreen init error: $e");
      if (!mounted) setState(() => isLoading = false);
    }
  }

  void filterEventsLocally() {
    setState(() {
      filteredEvents = events.where((e) {
        final matchesSearch = e.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.description.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesCategory = selectedCategory == "All" ||
            e.category.toLowerCase() == selectedCategory.toLowerCase();
        final matchesCollege = selectedCollege.isEmpty ||
            (e.college?.trim().toLowerCase() == selectedCollege.trim().toLowerCase());
        return matchesSearch && matchesCategory && matchesCollege;
      }).toList();
    });
  }

  void openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        DateTime now = DateTime.now();
        if (lastBackPressTime == null || now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Press back again to exit"),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: bgBlack,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 3,
          title: ShaderMask(
            shaderCallback: (bounds) => accentGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              "EVENTUS - $selectedCity",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.person), color: accentGreen, onPressed: openProfile),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF69F0AE)))
            : RefreshIndicator(
          color: accentGreen,
          onRefresh: () async {
            final success = await ApiService.loadEvents(city: selectedCity);
            if (success) {
              await _initHome();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Events refreshed successfully!")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("❌ Failed to load events")),
              );
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Search + Category
              // Search + Category
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.max, // take full width
                  children: [
                    Flexible(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Search events...",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800]?.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          ),
                          onChanged: (value) {
                            searchQuery = value;
                            filterEventsLocally();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800]?.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true, // important!
                              dropdownColor: Colors.grey[900],
                              style: const TextStyle(color: Colors.white),
                              items: categories
                                  .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedCategory = value;
                                    filterEventsLocally();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              if (cityColleges.containsKey(selectedCity))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Text("College: ", style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedCollege.isEmpty ? null : selectedCollege,
                        hint: const Text("Select College", style: TextStyle(color: Colors.white70)),
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        items: cityColleges[selectedCity]!
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCollege = value ?? "";
                            filterEventsLocally();
                          });
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Horizontal city buttons
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cities.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = city == selectedCity;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? null : Colors.grey[700],
                        foregroundColor: isSelected ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        setState(() {
                          selectedCity = city;
                          selectedCollege = "";
                          isLoading = true;
                        });
                        await _initHome();
                        filterEventsLocally();
                      },
                      child: Ink(
                        decoration: isSelected
                            ? BoxDecoration(
                          gradient: accentGradient,
                          borderRadius: BorderRadius.circular(20),
                        )
                            : null,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(city),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Event list
              if (filteredEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No events found for $selectedCity${selectedCollege.isNotEmpty ? " ($selectedCollege)" : ""}.",
                      style: TextStyle(color: textLightGrey, fontSize: 16),
                    ),
                  ),
                )
              else
                Column(
                  children: filteredEvents.map((e) {
                    return EventCard(
                      event: e,
                      userRole: currentRole,
                      userId: widget.userId,
                      onDelete: () async {
                        final success = await ApiService.deleteEvent(e.id);
                        if (success) {
                          setState(() {
                            events.removeWhere((ev) => ev.id == e.id);
                            filteredEvents.removeWhere((ev) => ev.id == e.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Event deleted")),
                          );
                        }
                      },
                      onNotInterested: () async {
                        final success = await ApiService.markNotInterested(e.id, widget.userId);
                        if (success) {
                          setState(() {
                            events.removeWhere((ev) => ev.id == e.id);
                            filteredEvents.removeWhere((ev) => ev.id == e.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Marked as Not Interested")),
                          );
                        }
                      },
                      onRate: (rating) async {
                        final success = await ApiService.rateEvent(e.id, rating);
                        if (success) {
                          setState(() {
                            e.rating = rating;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Rated successfully")),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        floatingActionButton: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                backgroundColor: null,
                heroTag: "add_event",
                onPressed: _handleAddEvent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.add, color: Colors.black, size: 28),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: "boxbot",
                backgroundColor: Colors.tealAccent,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BoxBotChatScreen()));
                },
                child: const Icon(Icons.chat, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddEvent() async {
    if (currentRole == "user") {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SubscriptionScreen(userId: widget.userId)),
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        currentRole = prefs.getString("userRole") ?? currentRole;
      });

      if (currentRole != "pro") return;
    }

    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEventScreen()));
    if (result is Map<String, dynamic>) {
      final newEvent = EventModel.fromJson(result);
      setState(() {
        events.insert(0, newEvent);
        filterEventsLocally();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event added successfully")),
      );
    }
  }
}

// ---------------- EventCard Widget ----------------
class EventCard extends StatefulWidget {
  final EventModel event;
  final String userRole;
  final int userId;
  final VoidCallback onDelete;
  final VoidCallback onNotInterested;
  final Function(double) onRate;

  const EventCard({
    required this.event,
    required this.userRole,
    required this.userId,
    required this.onDelete,
    required this.onNotInterested,
    required this.onRate,
    Key? key,
  }) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color accentGreen = const Color(0xFF69F0AE);
    final Color accentGreenLight = const Color(0xFFB9F6CA);
    final Color textLightGrey = Colors.grey[300]!;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.grey[850]!, Colors.grey[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isHovered
              ? [
            BoxShadow(
              color: accentGreen.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            )
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty)
                Image.network(
                  widget.event.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else if (widget.userRole == "pro" && widget.event.creatorId == widget.userId)
                InkWell(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    height: 160,
                    color: Colors.grey[900],
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add_a_photo, color: Colors.white70, size: 28),
                          SizedBox(width: 8),
                          Text("Add Image", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                          color: Colors.grey[900],
                          onSelected: (choice) async {
                            if (choice == "details") _showDetailsDialog(context);
                            else if (choice == "delete") widget.onDelete();
                            else if (choice == "not_interested") widget.onNotInterested();
                            else if (choice == "rate") _showRateDialog(context);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "details",
                              child: Text("View Details", style: TextStyle(color: Colors.white70)),
                            ),
                            if (widget.userRole == "pro" && widget.event.creatorId == widget.userId)
                              PopupMenuItem(
                                value: "delete",
                                child: Text("Delete", style: TextStyle(color: Colors.redAccent)),
                              ),
                            PopupMenuItem(
                              value: "not_interested",
                              child: Text("Not Interested", style: TextStyle(color: Colors.white70)),
                            ),
                            PopupMenuItem(
                              value: "rate",
                              child: Text("Rate Event", style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),

                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(widget.event.category, style: TextStyle(color: textLightGrey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "${widget.event.city}"
                                "${(widget.event.college ?? '').isNotEmpty ? " - ${widget.event.college}" : ""}"
                                "${(widget.event.address ?? '').isNotEmpty ? ", ${widget.event.address}" : ""}",
                            style: TextStyle(color: textLightGrey),
                          ),
                        ),
                      ],
                    ),
                    if ((widget.event.pincode ?? '').isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(widget.event.pincode!, style: TextStyle(color: textLightGrey)),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("${widget.event.date}", style: TextStyle(color: textLightGrey)),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1, color: Colors.white12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rating: ${widget.event.rating?.toStringAsFixed(1) ?? "0"}/5",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF69F0AE),
                          ),
                        ),
                        if ((widget.event.registrationLink ?? "").isNotEmpty)
                          InkWell(
                            onTap: () {
                              final uri = Uri.parse(widget.event.registrationLink!);
                              launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: accentGreenLight.withOpacity(0.3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF69F0AE), Color(0xFF00C853)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    final Color accentGreen = const Color(0xFF69F0AE);
    final Color accentGreenLight = const Color(0xFFB9F6CA);
    final Color textLightGrey = Colors.grey[300]!;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(widget.event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty)
                  Image.network(widget.event.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.category, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(widget.event.category, style: TextStyle(color: textLightGrey)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${widget.event.city}"
                            "${(widget.event.college ?? '').isNotEmpty ? " - ${widget.event.college}" : ""}"
                            "${(widget.event.address ?? '').isNotEmpty ? ", ${widget.event.address}" : ""}",
                        style: TextStyle(color: textLightGrey),
                      ),
                    ),
                  ],
                ),
                if ((widget.event.pincode ?? '').isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(widget.event.pincode!, style: TextStyle(color: textLightGrey)),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text("${widget.event.date}", style: TextStyle(color: textLightGrey)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.event.description, style: TextStyle(color: textLightGrey, fontSize: 14)),
                const SizedBox(height: 12),
                Text("Rating: ${widget.event.rating?.toStringAsFixed(1) ?? "0"}/5",
                    style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
                if ((widget.event.registrationLink ?? "").isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      final uri = Uri.parse(widget.event.registrationLink!);
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    borderRadius: BorderRadius.circular(12),
                    splashColor: accentGreenLight.withOpacity(0.3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentGreen, const Color(0xFF00C853)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text("Register",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close", style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  void _showRateDialog(BuildContext context) {
    double selectedRating = widget.event.rating ?? 3;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text("Rate ${widget.event.title}", style: const TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (ctx, setState) => Slider(
              value: selectedRating,
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: const Color(0xFF69F0AE),
              label: selectedRating.toString(),
              onChanged: (val) => setState(() => selectedRating = val),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                widget.onRate(selectedRating);
                Navigator.pop(ctx);
              },
              child: const Text("Submit", style: TextStyle(color: Color(0xFF69F0AE))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final File file = File(picked.path);

    // Upload image to server and get URL
    final uploadedUrl = await ApiService.uploadEventImage(widget.event.id, file);
    if (uploadedUrl != null) {
      setState(() {
        widget.event.imageUrl = uploadedUrl; // ✅ Use server URL
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Image uploaded successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to upload image")),
      );
    }
  }

}
