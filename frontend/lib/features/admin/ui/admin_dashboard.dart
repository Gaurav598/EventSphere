import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/admin/providers/admin_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.error != null
              ? Center(child: Text(adminProvider.error!))
              : adminProvider.myEvents.isEmpty
                  ? const Center(child: Text('You have not created any events.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: adminProvider.myEvents.length,
                      itemBuilder: (context, index) {
                        final event = adminProvider.myEvents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Capacity: ${event.registeredCount} / ${event.capacity}'),
                            trailing: Text(event.isRegistrationOpen ? 'OPEN' : 'CLOSED', style: TextStyle(color: event.isRegistrationOpen ? Colors.green : Colors.red)),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/create-event'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
