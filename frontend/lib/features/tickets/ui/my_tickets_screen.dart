import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/tickets/providers/ticket_provider.dart';

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
          ? const Center(child: CircularProgressIndicator())
          : ticketProvider.error != null
              ? Center(child: Text(ticketProvider.error!))
              : ticketProvider.myTickets.isEmpty
                  ? const Center(child: Text('You have no tickets yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ticketProvider.myTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = ticketProvider.myTickets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
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
