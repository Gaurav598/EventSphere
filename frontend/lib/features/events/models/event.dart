class Event {
  final String id;
  final String name;
  final String description;
  final String category;
  final String location;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final int capacity;
  final int registeredCount;
  final bool isRegistrationOpen;
  final bool isPrivate;
  final String? inviteCode;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    required this.eventDate,
    required this.registrationDeadline,
    required this.capacity,
    required this.registeredCount,
    required this.isRegistrationOpen,
    this.isPrivate = false,
    this.inviteCode,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      eventDate: DateTime.parse(json['eventDate'] ?? DateTime.now().toIso8601String()),
      registrationDeadline: DateTime.parse(json['registrationDeadline'] ?? DateTime.now().toIso8601String()),
      capacity: json['capacity'] ?? 0,
      registeredCount: json['registeredCount'] ?? 0,
      isRegistrationOpen: json['isRegistrationOpen'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      inviteCode: json['inviteCode'],
    );
  }
}
