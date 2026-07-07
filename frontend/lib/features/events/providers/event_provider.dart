import 'package:flutter/material.dart';
import 'package:frontend/core/models/paginated_response.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/events/services/event_service.dart';
import 'package:frontend/core/websocket_service.dart';
import 'dart:async';

class EventProvider extends ChangeNotifier {
  final EventService _eventService;

  List<Event> _events = [];
  Pagination? _pagination;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _wsSubscription;
  String? _lastSearchQuery;
  String? _lastCategory;

  EventProvider(this._eventService) {
    _wsSubscription = WebSocketService().stream.listen((message) {
      if (message['type'] == 'REGISTRATION_UPDATE' || message['type'] == 'EVENT_UPDATE') {
        if (_lastSearchQuery != null && _lastSearchQuery!.isNotEmpty) {
          searchEvents(_lastSearchQuery!);
        } else {
          fetchEvents(category: _lastCategory);
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  List<Event> get events => _events;
  Pagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEvents({String? category, int page = 1, int limit = 20}) async {
    _lastCategory = category;
    _lastSearchQuery = null;
    _setLoading(true);
    try {
      final response = await _eventService.getEvents(category: category, page: page, limit: limit);
      _events = response.data;
      _pagination = response.pagination;
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> searchEvents(String query, {int page = 1, int limit = 20}) async {
    _lastSearchQuery = query;
    _lastCategory = null;
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
      _error = e.toString();
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
