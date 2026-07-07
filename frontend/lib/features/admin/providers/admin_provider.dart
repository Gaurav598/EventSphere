import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/models/paginated_response.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/admin/services/admin_service.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/websocket_service.dart';
import 'dart:async';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  List<Event> _myEvents = [];
  Pagination? _pagination;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _analyticsSummary;
  List<dynamic> _topEvents = [];
  List<dynamic> _categoryWise = [];
  List<dynamic> _monthlyTrend = [];
  bool _isAnalyticsLoading = false;
  StreamSubscription? _wsSubscription;

  AdminProvider(this._adminService) {
    _wsSubscription = WebSocketService().stream.listen((message) {
      if (message['type'] == 'REGISTRATION_UPDATE' || message['type'] == 'EVENT_UPDATE') {
        // Silently refresh data
        fetchMyEvents();
        fetchAnalytics();
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  List<Event> get myEvents => _myEvents;
  Pagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic>? get analyticsSummary => _analyticsSummary;
  List<dynamic> get topEvents => _topEvents;
  List<dynamic> get categoryWise => _categoryWise;
  List<dynamic> get monthlyTrend => _monthlyTrend;
  bool get isAnalyticsLoading => _isAnalyticsLoading;

  int get activeEventCount => _pagination?.total ?? 0;

  Future<void> fetchMyEvents({int page = 1, int limit = 20}) async {
    _setLoading(true);
    try {
      final response = await _adminService.getMyEvents(page: page, limit: limit);
      _myEvents = response.data;
      _pagination = response.pagination;
      _setLoading(false);
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to fetch admin events';
      }
      _setLoading(false);
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    if (activeEventCount >= 3) {
      _error = 'You have reached the maximum limit of 3 active events. Delete or archive an existing event before creating another.';
      notifyListeners();
      return false;
    }
    
    _setLoading(true);
    try {
      await _adminService.createEvent(eventData);
      await fetchMyEvents();
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['error'] is Map) {
          _error = data['error']['message'];
        } else {
          _error = e.message;
        }
      } else {
        _error = e.toString();
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    _setLoading(true);
    try {
      await _adminService.updateEvent(eventId, eventData);
      await fetchMyEvents();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to update event';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    _setLoading(true);
    try {
      await _adminService.deleteEvent(eventId);
      await fetchMyEvents();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to delete event';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> closeRegistration(String eventId) async {
    _setLoading(true);
    try {
      await _adminService.closeRegistration(eventId);
      await fetchMyEvents();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to close registration';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getEventRegistrations(String eventId) async {
    try {
      return await _adminService.getEventRegistrations(eventId);
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateRegistrationStatus(String regId, String status) async {
    try {
      await _adminService.updateRegistrationStatus(regId, status);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to update registration status';
      }
      return false;
    }
  }

  Future<String?> exportRegistrations(String eventId) async {
    try {
      return await _adminService.exportRegistrations(eventId);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchAnalytics() async {
    _isAnalyticsLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _adminService.getAnalyticsSummary(),
        _adminService.getTopEvents(),
        _adminService.getCategoryWise(),
        _adminService.getMonthlyTrend(),
      ]);
      _analyticsSummary = results[0] as Map<String, dynamic>;
      _topEvents = results[1] as List<dynamic>;
      _categoryWise = results[2] as List<dynamic>;
      _monthlyTrend = results[3] as List<dynamic>;
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to load analytics';
      }
    }
    _isAnalyticsLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }
}
