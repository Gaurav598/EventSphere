import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/events/services/event_service.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:frontend/features/tickets/providers/ticket_provider.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final service = context.read<EventService>();
      final event = await service.getEventDetails(widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final ticketProvider = context.read<TicketProvider>();
    final success = await ticketProvider.register(widget.eventId);
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully registered for event!')),
      );
      _loadEvent(); // Refresh event to get updated capacity
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ticketProvider.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final ticketProvider = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_event!.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_event!.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('${_event!.category.toUpperCase()} • ${_event!.location}', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const Divider(height: 32),
            Text('Description', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_event!.description),
            const SizedBox(height: 16),
            Text('Date: ${_event!.eventDate.toLocal().toString().split('.')[0]}'),
            const SizedBox(height: 16),
            Text('Capacity: ${_event!.registeredCount} / ${_event!.capacity}'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_event!.isRegistrationOpen && _event!.registeredCount < _event!.capacity && !ticketProvider.isLoading)
                  ? _register
                  : null,
              child: ticketProvider.isLoading
                  ? const CircularProgressIndicator()
                  : Text(_event!.isRegistrationOpen ? 'REGISTER NOW' : 'REGISTRATION CLOSED'),
            )
          ],
        ),
      ),
    );
  }
}
