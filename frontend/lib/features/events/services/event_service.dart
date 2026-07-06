import 'package:dio/dio.dart';
import 'package:frontend/core/models/paginated_response.dart';
import 'package:frontend/features/events/models/event.dart';

class EventService {
  final Dio dio;

  EventService(this.dio);

  Future<PaginatedResponse<Event>> getEvents({int page = 1, int limit = 10, String? category}) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    
    final response = await dio.get('/events', queryParameters: queryParams);
    return PaginatedResponse<Event>.fromJson(response.data, Event.fromJson);
  }

  Future<PaginatedResponse<Event>> searchEvents(String query, {int page = 1, int limit = 10}) async {
    final response = await dio.get('/events/search', queryParameters: {'q': query, 'page': page, 'limit': limit});
    return PaginatedResponse<Event>.fromJson(response.data, Event.fromJson);
  }

  Future<Event> getEventDetails(String id) async {
    final response = await dio.get('/events/$id');
    return Event.fromJson(response.data['data']);
  }
}
