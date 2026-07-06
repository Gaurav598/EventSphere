// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/events/providers/event_provider.dart';
import 'package:frontend/features/events/services/event_service.dart';
import 'package:frontend/features/tickets/providers/ticket_provider.dart';
import 'package:frontend/features/tickets/services/ticket_service.dart';
import 'package:frontend/features/admin/providers/admin_provider.dart';
import 'package:frontend/features/admin/services/admin_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final apiClient = ApiClient();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
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

    // Verify that the app mounts successfully
    expect(find.byType(EventSphereApp), findsOneWidget);
  });
}

