import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:stiuffcoletorinventario/core/providers/inventory_provider.dart';
import 'package:stiuffcoletorinventario/features/about/views/about_page.dart';
import 'package:stiuffcoletorinventario/features/camera/views/camera_page.dart';
import 'package:stiuffcoletorinventario/features/home/controllers/tag_filter_controller.dart';
import 'package:stiuffcoletorinventario/features/login/view/login_screen.dart';
import 'package:stiuffcoletorinventario/features/settings/controllers/pdf_report_controller.dart';
import 'features/home/views/home_page.dart';
import 'features/settings/views/settings_page.dart';
import 'shared/utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();
  await initializeDateFormatting('pt_BR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => TagFilterController()),
        ChangeNotifierProvider(create: (_) => PdfReportController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coletor Inventário',
      theme: ThemeData(
        primarySwatch: AppColors.primaryColor,
        appBarTheme: const AppBarTheme(
          elevation: 2.0,
          shadowColor: AppColors.shadowColor,
          color: AppColors.appBarColor,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
        splashColor: AppColors.lightOrangeSplashColor,
      ),
      debugShowCheckedModeBanner: true,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
        '/camera': (context) => const CameraPage(),
      },
    );
  }
}
