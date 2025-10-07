import 'package:flutter/material.dart';
import 'dart:io' show Platform; // For desktop platform detection
import 'package:sqflite/sqflite.dart'; // Provides global databaseFactory
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // FFI support for desktop
import 'member_list_page.dart';
// NOTE: All logic is split into flat files (no subfolders) for simplicity.
// main.dart only wires the root widget.

// App Entry ---------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqlite FFI for desktop (MUST be before any DB usage)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gym Manager',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: const MemberListPage(),
  );
}

// Member List / Dashboard -------------------------------------------------
