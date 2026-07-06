import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/tickets/providers/ticket_provider.dart';
import 'package:frontend/shared/widgets/loading_view.dart';
import 'package:frontend/shared/widgets/error_view.dart';
import 'package:frontend/shared/widgets/empty_state_view.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchMyTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: ticketProvider.isLoading
          ? const LoadingView()
          : ticketProvider.error != null
              ? ErrorView(
                  message: ticketProvider.error!,
                  onRetry: () => ticketProvider.fetchMyTickets(),
                )
              : ticketProvider.myTickets.isEmpty
                  ? const EmptyStateView(message: 'You have no tickets yet.',
                      icon: Icons.confirmation_num_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ticketProvider.myTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = ticketProvider.myTickets[index];
                        return Card(
                          child: ListTile(
                            title: Text(ticket.event?.name ?? 'Unknown Event'),
                            subtitle: Text('Status: ${ticket.status}'),
                            trailing: const Icon(Icons.qr_code),
                            onTap: () {
                              context.push('/tickets/${ticket.id}', extra: ticket);
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
