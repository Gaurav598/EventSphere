import 'package:dio/dio.dart';
import 'package:frontend/features/tickets/models/ticket.dart';

class TicketService {
  final Dio dio;

  TicketService(this.dio);

  Future<Ticket> registerForEvent(String eventId) async {
    final response = await dio.post('/events/$eventId/register');
    return Ticket.fromJson(response.data['data']);
  }

  Future<List<Ticket>> getMyTickets() async {
    final response = await dio.get('/registrations/me');
    return (response.data['data'] as List).map((e) => Ticket.fromJson(e)).toList();
  }
}
