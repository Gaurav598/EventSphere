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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.name} Registrations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
          )
        ],
      ),
      body: _isLoading
          ? const LoadingView()
          : _registrations == null || _registrations!.isEmpty
              ? const EmptyStateView(
                  message: 'No registrations for this event yet.',
                  icon: Icons.group_off,
                )
              : ListView.builder(
                  itemCount: _registrations!.length,
                  itemBuilder: (context, index) {
                    final reg = _registrations![index];
                    final user = reg['user'] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(user['name'] ?? 'Unknown User'),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: Text(
                        reg['status'] ?? '',
                        style: TextStyle(
                          color: reg['status'] == 'confirmed' ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
