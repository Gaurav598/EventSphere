import 'package:dio/dio.dart';
import 'package:frontend/features/events/models/event.dart';

class EventService {
  final Dio dio;

  EventService(this.dio);

  Future<List<Event>> getEvents({int page = 1, int limit = 10, String? category}) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    
    final response = await dio.get('/events', queryParameters: queryParams);
    return (response.data['data'] as List).map((e) => Event.fromJson(e)).toList();
  }

  Future<List<Event>> searchEvents(String query) async {
    final response = await dio.get('/events/search', queryParameters: {'q': query});
    return (response.data['data'] as List).map((e) => Event.fromJson(e)).toList();
  }

  Future<Event> getEventDetails(String id) async {
    final response = await dio.get('/events/$id');
    return Event.fromJson(response.data['data']);
  }
}
