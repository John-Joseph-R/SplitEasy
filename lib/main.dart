import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'providers/bill_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = BillProvider();
  await provider.loadFromStorage();
  runApp(SpliteasyApp(provider: provider));
}

class SpliteasyApp extends StatelessWidget {
  final BillProvider provider;
  const SpliteasyApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BillProvider>.value(
      value: provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Spliteasy',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}