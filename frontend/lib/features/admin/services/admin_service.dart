import 'package:dio/dio.dart';
import 'package:frontend/features/events/models/event.dart';

class AdminService {
  final Dio dio;

  AdminService(this.dio);

  Future<List<Event>> getMyEvents() async {
    final response = await dio.get('/admin/events');
    return (response.data['data'] as List).map((e) => Event.fromJson(e)).toList();
  }

  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    final response = await dio.post('/admin/events', data: eventData);
    return Event.fromJson(response.data['data']);
  }
}
