import 'package:flutter/material.dart';
import '../../dashboard/views/dashboard_screen.dart';

/// Legacy export/alias forwarding to the full Dashboard implementation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
