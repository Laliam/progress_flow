import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uptrack/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('App boots to Welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UpTrackApp()));
    await tester.pumpAndSettle();

    expect(find.text('UpTrack'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
