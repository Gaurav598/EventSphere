import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/events/providers/event_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/shared/widgets/loading_view.dart';
import 'package:frontend/shared/widgets/error_view.dart';
import 'package:frontend/shared/widgets/empty_state_view.dart';
import 'package:frontend/shared/widgets/animated_dialog.dart';
import 'package:frontend/core/theme_provider.dart';

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
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Discover Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'Join Private Event',
            onPressed: () => _showJoinPrivateDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_num),
            onPressed: () => context.push('/tickets'),
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AnimatedDialog.show(context, title: 'Logged Out', message: 'You have logged out successfully.', icon: Icons.check_circle_outline, color: Colors.green);
              authProvider.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/auth_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Column(
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
      ),
    );
  }

  void _showJoinPrivateDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Private Event'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: 'Enter Invite Code (e.g. PRV-A1B2)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              
              Navigator.of(ctx).pop();
              final provider = context.read<EventProvider>();
              final eventId = await provider.resolveInviteCode(code);
              
              if (eventId != null && context.mounted) {
                context.push('/events/$eventId');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.error ?? 'Invalid Code')),
                );
              }
            },
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }
}
