import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Core
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/theme.dart';

// Services
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/events/services/event_service.dart';
import 'package:frontend/features/tickets/services/ticket_service.dart';
import 'package:frontend/features/admin/services/admin_service.dart';

// Providers
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/events/providers/event_provider.dart';
import 'package:frontend/features/tickets/providers/ticket_provider.dart';
import 'package:frontend/features/admin/providers/admin_provider.dart';

// UI - Auth
import 'package:frontend/features/auth/ui/splash_screen.dart';
import 'package:frontend/features/auth/ui/login_screen.dart';
import 'package:frontend/features/auth/ui/signup_screen.dart';

// UI - User
import 'package:frontend/features/events/ui/event_list_screen.dart';
import 'package:frontend/features/events/ui/event_details_screen.dart';
import 'package:frontend/features/tickets/ui/my_tickets_screen.dart';
import 'package:frontend/features/tickets/ui/ticket_details_screen.dart';
import 'package:frontend/features/tickets/models/ticket.dart';

// UI - Admin
import 'package:frontend/features/admin/ui/admin_dashboard.dart';
import 'package:frontend/features/admin/ui/create_event_screen.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService(apiClient.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => EventProvider(EventService(apiClient.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => TicketProvider(TicketService(apiClient.dio)),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(AdminService(apiClient.dio)),
        ),
      ],
      child: const EventSphereApp(),
    ),
  );
}

class EventSphereApp extends StatefulWidget {
  const EventSphereApp({super.key});

  @override
  State<EventSphereApp> createState() => _EventSphereAppState();
}

class _EventSphereAppState extends State<EventSphereApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventListScreen(),
        ),
        GoRoute(
          path: '/events/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EventDetailsScreen(eventId: id);
          },
        ),
        GoRoute(
          path: '/tickets',
          builder: (context, state) => const MyTicketsScreen(),
        ),
        GoRoute(
          path: '/tickets/:id',
          builder: (context, state) {
            final ticket = state.extra as Ticket;
            return TicketDetailsScreen(ticket: ticket);
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin/create-event',
          builder: (context, state) => const CreateEventScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EventSphere',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
