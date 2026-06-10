import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.light,
          ),
          fontFamily: 'Poppins', // optional, remove if not using
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
            ),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E1B4B),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1B4B),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}