import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventorytracker/screens/home.dart';
import 'package:inventorytracker/screens/login.dart';
import 'package:inventorytracker/screens/signup.dart'; // Ensure the import is correct
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/annotations.dart';
import 'login_test.mocks.dart';  // Generated mock file

@GenerateMocks([FirebaseAuth, UserCredential])
void main() {
  final mockFirebaseAuth = MockFirebaseAuth();
  final mockUserCredential = MockUserCredential();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(); // Initialize Firebase
  });

  group('Login Widget Tests', () {
    testWidgets('displays form validation errors when email and password are empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Login()));

      // Tap the login button without entering any data
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Expect to find validation error messages
      expect(find.text('Please Enter E-mail'), findsOneWidget);
      expect(find.text('Please Enter Password'), findsOneWidget);
    });

    testWidgets('successful login with valid credentials', (WidgetTester tester) async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com', password: 'password123'))
          .thenAnswer((_) async => mockUserCredential);

      await tester.pumpWidget(const MaterialApp(home: Login()));

      // Enter valid email and password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap the login button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify signInWithEmailAndPassword was called
      verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com', password: 'password123')).called(1);

      // Expect to see Home page after login
      expect(find.byType(Home), findsOneWidget);
    });

    testWidgets('login fails with incorrect credentials', (WidgetTester tester) async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'wrong@example.com', password: 'wrongpassword'))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      await tester.pumpWidget(const MaterialApp(home: Login()));

      // Enter wrong email and password
      await tester.enterText(find.byType(TextFormField).first, 'wrong@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');

      // Tap the login button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Check for error message
      expect(find.text('No User Found for that Email'), findsOneWidget);
    });

    testWidgets('navigates to signup page on button press', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Login()));

      // Tap the signup button
      await tester.tap(find.text("Don’t have an account? Register"));
      await tester.pumpAndSettle();

      // Expect to find Signup page
      expect(find.byType(Signup), findsOneWidget);
    });
  });
}
