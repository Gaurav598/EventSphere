import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/admin/providers/admin_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/shared/widgets/loading_view.dart';
import 'package:frontend/shared/widgets/error_view.dart';
import 'package:frontend/shared/widgets/empty_state_view.dart';
import 'package:frontend/shared/widgets/animated_dialog.dart';
import 'package:frontend/core/theme_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchMyEvents();
      context.read<AdminProvider>().fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Events', icon: Icon(Icons.event)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            ],
          ),
          actions: [
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
          child: TabBarView(
            children: [
              _buildEventsTab(adminProvider),
              _buildAnalyticsTab(adminProvider),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/admin/create-event'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEventsTab(AdminProvider adminProvider) {
    if (adminProvider.isLoading) return const LoadingView();
    if (adminProvider.error != null) {
      return ErrorView(
        message: adminProvider.error!,
        onRetry: () => adminProvider.fetchMyEvents(),
      );
    }
    if (adminProvider.myEvents.isEmpty) {
      return const EmptyStateView(
        message: 'You have not created any events.',
        icon: Icons.event_note,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: adminProvider.myEvents.length,
      itemBuilder: (context, index) {
        final event = adminProvider.myEvents[index];
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Capacity: ${event.registeredCount} / ${event.capacity}'),
                trailing: Text(event.isRegistrationOpen ? 'OPEN' : 'CLOSED', 
                    style: TextStyle(color: event.isRegistrationOpen ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              OverflowBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: () => context.push('/admin/events/${event.id}/edit', extra: event),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.people, size: 18),
                    label: const Text('Attendees'),
                    onPressed: () => context.push('/admin/events/${event.id}/registrations', extra: event),
                  ),
                  if (event.isRegistrationOpen)
                    TextButton.icon(
                      icon: const Icon(Icons.block, size: 18, color: Colors.orange),
                      label: const Text('Close', style: TextStyle(color: Colors.orange)),
                      onPressed: () => adminProvider.closeRegistration(event.id),
                    ),
                  if (event.isPrivate && event.inviteCode != null)
                    TextButton.icon(
                      icon: const Icon(Icons.share, size: 18, color: Colors.blue),
                      label: const Text('Share', style: TextStyle(color: Colors.blue)),
                      onPressed: () => _showShareDialog(context, event.inviteCode!),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmDelete(context, event.id),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(AdminProvider adminProvider) {
    if (adminProvider.isAnalyticsLoading) return const LoadingView();
    if (adminProvider.error != null) {
      return ErrorView(
        message: adminProvider.error!,
        onRetry: () => adminProvider.fetchAnalytics(),
      );
    }
    if (adminProvider.analyticsSummary == null) {
      return const EmptyStateView(message: 'No analytics available', icon: Icons.analytics_outlined);
    }

    final summary = adminProvider.analyticsSummary!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Registrations', summary['totalRegistrations'].toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Upcoming Events', summary['upcomingEventsCount'].toString())),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Top Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...adminProvider.topEvents.map((e) {
          final evt = e['event'] as Map<String, dynamic>;
          return ListTile(
            title: Text(evt['name'] ?? ''),
            trailing: Text('${e['totalRegistrations']} reg'),
          );
        }),
        const SizedBox(height: 24),
        const Text('Registrations by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...adminProvider.categoryWise.map((c) => ListTile(
          title: Text(c['category'] ?? 'Unknown'),
          trailing: Text(c['count'].toString()),
        )),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<AdminProvider>().deleteEvent(eventId);
    }
  }

  void _showShareDialog(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Attendees', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this QR code or the invite code below.'),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: inviteCode,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              inviteCode,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('COPY CODE'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied to clipboard!')));
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
