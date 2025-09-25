import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_calculator/main.dart';

void main() {
  group('Jewelry Shop Billing App Tests', () {
    testWidgets('App should launch with dashboard', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const JewelryShopApp());

      // Verify the dashboard title is present
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Dashboard should have quick action cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const JewelryShopApp());

      // Verify quick action cards are present
      expect(find.text('New Bill'), findsOneWidget);
      expect(find.text('Bills History'), findsOneWidget);
      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);
    });

    testWidgets('Navigation drawer should be accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const JewelryShopApp());

      // Open the drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer items
      expect(find.text('Jewelry Shop Admin'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('New Bill'), findsOneWidget);
      expect(find.text('Bills History'), findsOneWidget);
    });
  });
}
