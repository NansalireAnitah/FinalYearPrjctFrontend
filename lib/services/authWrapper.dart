import 'package:flutter/material.dart';
import 'package:front_end/providers/auth_provider.dart';
import 'package:front_end/screens/admin_dashboard_screen.dart';
import 'package:front_end/screens/home_screen.dart';
import 'package:front_end/screens/login_screen.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint('AuthWrapper: isLoading = ${authProvider.isLoading}');
        debugPrint(
            'AuthWrapper: isInitialized = ${authProvider.isInitialized}');
        debugPrint('AuthWrapper: user = ${authProvider.user}');
        debugPrint('AuthWrapper: role = ${authProvider.role}');

        // Show loading while initializing or during auth operations
        if (authProvider.isLoading || !authProvider.isInitialized) {
          debugPrint('AuthWrapper: Showing loading screen');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // CRITICAL FIX: Check user authentication first
        if (authProvider.user == null) {
          debugPrint('AuthWrapper: No user authenticated, showing LoginScreen');
          return const LoginScreen();
        }

        final role = authProvider.role;
        debugPrint('AuthWrapper: User authenticated with role: $role');

        // Handle case where role might still be loading
        if (role == null) {
          debugPrint('AuthWrapper: Role still loading for authenticated user');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        // Route based on role
        return role == 'admin' ? const AdminDashboard() : const HomeScreen();
      },
    );
  }
}
