import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/events/providers/event_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/shared/widgets/loading_view.dart';
import 'package:frontend/shared/widgets/error_view.dart';
import 'package:frontend/shared/widgets/empty_state_view.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_num),
            onPressed: () => context.push('/tickets'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    eventProvider.fetchEvents();
                  },
                ),
              ),
              onSubmitted: (query) => eventProvider.searchEvents(query),
            ),
          ),
          Expanded(
            child: eventProvider.isLoading
                ? const LoadingView()
                : eventProvider.error != null
                    ? ErrorView(
                        message: eventProvider.error!,
                        onRetry: () => eventProvider.fetchEvents(),
                      )
                    : eventProvider.events.isEmpty
                        ? const EmptyStateView(
                            message: 'No events found',
                            icon: Icons.event_busy,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: eventProvider.events.length,
                            itemBuilder: (context, index) {
                              final event = eventProvider.events[index];
                              return Card(
                                child: ListTile(
                                  title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${event.category} • ${event.location}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.push('/events/${event.id}'),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
