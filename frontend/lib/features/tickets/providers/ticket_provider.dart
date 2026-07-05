import 'package:flutter/material.dart';
import 'package:frontend/features/tickets/models/ticket.dart';
import 'package:frontend/features/tickets/services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  final TicketService _ticketService;

  List<Ticket> _myTickets = [];
  bool _isLoading = false;
  String? _error;

  TicketProvider(this._ticketService);

  List<Ticket> get myTickets => _myTickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyTickets() async {
    _setLoading(true);
    try {
      _myTickets = await _ticketService.getMyTickets();
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to fetch tickets';
      _setLoading(false);
    }
  }

  Future<bool> register(String eventId) async {
    _setLoading(true);
    try {
      await _ticketService.registerForEvent(eventId);
      await fetchMyTickets();
      return true;
    } catch (e) {
      _error = 'Registration failed. Event might be full or already registered.';
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
