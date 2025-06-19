// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:admin/pages/dashboard.dart';
import 'package:admin/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Set the isLoggedIn value for the test
    bool isLoggedIn = false;

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(isLoggedIn: isLoggedIn));

    // Verify that the Login screen is shown when not logged in.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(Dashboard),
        findsNothing); // Assuming Dashboard is the screen when logged in

    // Now, let's simulate the login state.
    isLoggedIn = true;

    // Rebuild the app with the updated isLoggedIn value.
    await tester.pumpWidget(MyApp(isLoggedIn: isLoggedIn));

    // Verify that the Dashboard screen is shown when logged in.
    expect(find.byType(Dashboard), findsOneWidget);
    expect(find.byType(LoginScreen),
        findsNothing); // Ensure Login screen is not shown
  });
}
