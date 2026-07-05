import 'package:flutter/material.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/admin/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  List<Event> _myEvents = [];
  bool _isLoading = false;
  String? _error;

  AdminProvider(this._adminService);

  List<Event> get myEvents => _myEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyEvents() async {
    _setLoading(true);
    try {
      _myEvents = await _adminService.getMyEvents();
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to fetch admin events';
      _setLoading(false);
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _setLoading(true);
    try {
      await _adminService.createEvent(eventData);
      await fetchMyEvents();
      return true;
    } catch (e) {
      _error = 'Failed to create event';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }
}
