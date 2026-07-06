import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/admin/providers/admin_provider.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/shared/widgets/loading_view.dart';
import 'package:frontend/shared/widgets/empty_state_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EventRegistrationsScreen extends StatefulWidget {
  final Event event;

  const EventRegistrationsScreen({super.key, required this.event});

  @override
  State<EventRegistrationsScreen> createState() => _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState extends State<EventRegistrationsScreen> {
  List<Map<String, dynamic>>? _registrations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() => _isLoading = true);
    final provider = context.read<AdminProvider>();
    final data = await provider.getEventRegistrations(widget.event.id);
    if (mounted) {
      setState(() {
        _registrations = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    final provider = context.read<AdminProvider>();
    final csvData = await provider.exportRegistrations(widget.event.id);
    if (csvData != null && mounted) {
      if (kIsWeb) {
        final uri = Uri.parse('data:text/csv;charset=utf-8,${Uri.encodeComponent(csvData)}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch CSV export.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV export is currently fully supported on Web. App export coming soon.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export registrations')),
        );
      }
    }
  }

  Future<void> _updateStatus(String regId, String status) async {
    final provider = context.read<AdminProvider>();
    final success = await provider.updateRegistrationStatus(regId, status);
    if (success && mounted) {
      await _loadRegistrations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration $status!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to update status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.event.name} Registrations')),
        body: const LoadingView(),
      );
    }

    final confirmed = _registrations?.where((r) => r['status'] == 'confirmed').toList() ?? [];
    final pending = _registrations?.where((r) => r['status'] == 'pending').toList() ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.event.name} Registrations'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportCsv,
              tooltip: 'Export CSV',
            )
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Confirmed (${confirmed.length})'),
              Tab(text: 'Pending (${pending.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(confirmed, false),
            _buildList(pending, true),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, bool isPending) {
    if (list.isEmpty) {
      return EmptyStateView(
        message: 'No ${isPending ? 'pending' : 'confirmed'} registrations.',
        icon: Icons.group_off,
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final reg = list[index];
        final user = reg['user'] as Map<String, dynamic>;
        return ListTile(
          title: Text(user['name'] ?? 'Unknown User'),
          subtitle: Text(user['email'] ?? ''),
          trailing: isPending
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _updateStatus(reg['_id'] ?? reg['id'], 'confirmed'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateStatus(reg['_id'] ?? reg['id'], 'rejected'),
                    ),
                  ],
                )
              : Text(
                  reg['status']?.toUpperCase() ?? '',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }
}
