import 'package:flutter/material.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/events/services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService;

  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  EventProvider(this._eventService);

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEvents({String? category}) async {
    _setLoading(true);
    try {
      _events = await _eventService.getEvents(category: category);
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to fetch events';
      _setLoading(false);
    }
  }

  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      await fetchEvents();
      return;
    }
    _setLoading(true);
    try {
      _events = await _eventService.searchEvents(query);
      _setLoading(false);
    } catch (e) {
      _error = 'Search failed';
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }
}
