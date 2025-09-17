class EventModel {
  final int id; // Added for deletion support
  final String title;
  final String description;
  final String date;
  final String location;
  final String category;
  final String subcategory;
  final String url;
  final String startDate;
  final String? registrationLink;
  final String city;
  final String? college;
  double? rating;
  final int? creatorId;
  final List<dynamic>? notInterestedUsers;
  final List<String> tags;
  String? imageUrl;
  final String? address;
  final String? pincode;

  EventModel({
    required this.id, // Added
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.category,
    required this.subcategory,
    required this.url,
    required this.startDate,
    this.registrationLink,
    required this.city,
    required this.tags,
    this.rating,
    this.creatorId,
    this.notInterestedUsers,
    this.college,
    this.imageUrl,
    this.address,
    this.pincode,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? 0, // Added
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      url: json['url'] ?? '',
      startDate: json['startDate'] ?? '',
      registrationLink: json['registration_link'] ?? json['registrationLink'] ?? '',
      city: json['city'] ?? '',
      college: json['college'] ?? "",
      rating: (json['rating'] != null) ? (json['rating'] as num).toDouble() : null,
      creatorId: json['creator_id'],
      notInterestedUsers: json['not_interested_users'],
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
      address: json['address'],       // new
      pincode: json['pincode'],
    );
  }
}
