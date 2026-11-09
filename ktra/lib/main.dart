import 'package:flutter/material.dart';
import 'package:ktra/services/api_service.dart';
import 'package:ktra/services/notification_service.dart';
import 'package:ktra/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.taiCauHinh();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bo12 = BorderRadius.circular(12);
    return MaterialApp(
      title: 'KT-GK Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        scaffoldBackgroundColor: const Color(0xFFF3F6FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3F6FB),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF12305C),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F6FB),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: bo12,
            borderSide: BorderSide.none,
          ),
        ),
      ),
      // máy để cỡ chữ quá lớn thì giới hạn lại để giao diện không bị tràn
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: child!,
      ),
      home: const HomeView(),
    );
  }
}
