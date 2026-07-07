import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/admin/providers/admin_provider.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/shared/widgets/loading_view.dart';
import 'package:frontend/shared/widgets/empty_state_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:frontend/shared/widgets/animated_confirm_dialog.dart';
import 'package:frontend/shared/widgets/animated_toast.dart';
import 'dart:io';

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
          if (mounted) AnimatedToast.show(context, message: 'Could not launch CSV export.', isError: true);
        }
      } else {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/registrations_${widget.event.id}.csv');
          await file.writeAsString(csvData);
          
          if (mounted) {
            final box = context.findRenderObject() as RenderBox?;
            await Share.shareXFiles(
              [XFile(file.path)],
              subject: '${widget.event.name} Registrations',
              sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
            );
          }
        } catch (e) {
          if (mounted) {
            AnimatedToast.show(context, message: 'Failed to save CSV: $e', isError: true);
          }
        }
      }
    } else {
      if (mounted) {
        AnimatedToast.show(context, message: 'Failed to export registrations', isError: true);
      }
    }
  }

  Future<void> _updateStatus(String regId, String status) async {
    final provider = context.read<AdminProvider>();
    final success = await provider.updateRegistrationStatus(regId, status);
    if (success && mounted) {
      await _loadRegistrations();
      if (!mounted) return;
      AnimatedToast.show(context, message: 'Registration $status!', isError: false);
    } else if (mounted) {
      AnimatedToast.show(context, message: provider.error ?? 'Failed to update status', isError: true);
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

    final bool isPrivate = widget.event.isPrivate;

    if (!isPrivate) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.event.name} Registrations'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push('/admin/events/${widget.event.id}/scan'),
              tooltip: 'Scan Ticket',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportCsv,
              tooltip: 'Export CSV',
            )
          ],
        ),
        body: _buildList(confirmed, false),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.event.name} Registrations'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push('/admin/events/${widget.event.id}/scan'),
              tooltip: 'Scan Ticket',
            ),
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
      return EmptyStateView(message: 'No ${isPending ? 'pending' : 'confirmed'} registrations.',
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
                      onPressed: () => _updateStatus(reg['registrationId'] ?? reg['_id'] ?? reg['id'], 'confirmed'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateStatus(reg['registrationId'] ?? reg['_id'] ?? reg['id'], 'rejected'),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reg['status']?.toUpperCase() ?? '',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Cancel Registration',
                      onPressed: () async {
                        final confirm = await AnimatedConfirmDialog.show(
                          context,
                          title: 'Cancel Ticket',
                          message: 'Are you sure you want to cancel this registration? The user will be rejected.',
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                        );
                        if (confirm && context.mounted) {
                          _updateStatus(reg['registrationId'] ?? reg['_id'] ?? reg['id'], 'rejected');
                        }
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}
