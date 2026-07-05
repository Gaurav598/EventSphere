import 'package:frontend/features/events/models/event.dart';

class Ticket {
  final String id;
  final String eventId;
  final String userId;
  final String qrCodeData;
  final String status;
  final DateTime registeredAt;
  final Event? event;

  Ticket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.qrCodeData,
    required this.status,
    required this.registeredAt,
    this.event,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['_id'] ?? json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      userId: json['userId'] ?? '',
      qrCodeData: json['qrCodeData'] ?? '',
      status: json['status'] ?? '',
      registeredAt: DateTime.parse(json['registeredAt'] ?? DateTime.now().toIso8601String()),
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
    );
  }
}
