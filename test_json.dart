import 'dart:convert';

void main() {
  final now = DateTime.now();
  final data = {
    "name": "Test",
    "description": "Test desc",
    "category": "conference",
    "location": "location",
    "eventDate": now.toUtc().toIso8601String(),
    "registrationDeadline": now.toUtc().toIso8601String(),
    "capacity": 100,
    "isPrivate": false,
  };
  print(jsonEncode(data));
}
