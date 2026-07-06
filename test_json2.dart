import 'dart:convert';
import 'package:frontend/features/events/models/event.dart';

void main() {
  final jsonString = '{"name":"eryerher","description":"rggerrh","category":"conferenceergee5r","location":"ergeqrh","eventDate":"2026-07-08T18:30:00Z","registrationDeadline":"2026-07-08T18:30:00Z","capacity":77,"categoryFields":{},"isPrivate":false,"_id":"6a4ba7325948037e2c9d98dd","registeredCount":0,"isRegistrationOpen":true,"isDeleted":false,"inviteCode":null,"createdBy":"6a4b8ae7fc2664f54d87b478","createdAt":"2026-07-06T13:01:38.587000Z","updatedAt":"2026-07-06T13:01:38.587000Z"}';
  try {
    final event = Event.fromJson(jsonDecode(jsonString));
    print("Success: ${event.id}");
  } catch (e) {
    print("Error: $e");
  }
}
