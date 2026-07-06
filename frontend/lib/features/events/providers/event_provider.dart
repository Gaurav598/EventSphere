import 'package:flutter/material.dart';
import 'package:frontend/core/models/paginated_response.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/events/services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService;

  List<Event> _events = [];
  Pagination? _pagination;
  bool _isLoading = false;
  String? _error;

  EventProvider(this._eventService);

  List<Event> get events => _events;
  Pagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEvents({String? category, int page = 1, int limit = 20}) async {
    _setLoading(true);
    try {
      final response = await _eventService.getEvents(category: category, page: page, limit: limit);
      _events = response.data;
      _pagination = response.pagination;
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to fetch events';
      _setLoading(false);
    }
  }

  Future<void> searchEvents(String query, {int page = 1, int limit = 20}) async {
    if (query.isEmpty) {
      await fetchEvents();
      return;
    }
    _setLoading(true);
    try {
      final response = await _eventService.searchEvents(query, page: page, limit: limit);
      _events = response.data;
      _pagination = response.pagination;
      _setLoading(false);
    } catch (e) {
      _error = 'Search failed';
      _setLoading(false);
    }
  }

  Future<String?> resolveInviteCode(String inviteCode) async {
    _setLoading(true);
    try {
      final event = await _eventService.getEventByInviteCode(inviteCode);
      _setLoading(false);
      return event.id;
    } catch (e) {
      _error = 'Invalid invite code or event not found';
      _setLoading(false);
      return null;
    }
  }

  Future<Event> getEventDetails(String id) async {
    return await _eventService.getEventDetails(id);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }
}
