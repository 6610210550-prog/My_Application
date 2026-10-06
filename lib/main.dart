import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services & Repositories
import 'services/purchase_service.dart';
import 'repositories/purchase_repository.dart';

// ViewModels
import 'viewmodels/purchase_viewmodel.dart';
import 'viewmodels/test_viewmodel.dart'; // 📌 1. Import TestViewModel เข้ามา

// Screens
import 'views/purchase_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // 1. ลงทะเบียน Data Service และ Repository
        Provider(create: (_) => PurchaseService()),
        ProxyProvider<PurchaseService, PurchaseRepository>(
          update: (_, service, __) => PurchaseRepository(service: service),
        ),

        // 2. ลงทะเบียน ViewModel สำหรับการรับซื้อน้ำยาง
        ChangeNotifierProxyProvider<PurchaseRepository, PurchaseViewModel>(
          create: (context) => PurchaseViewModel(
            repository: context.read<PurchaseRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? PurchaseViewModel(repository: repository),
        ),

        // 📌 3. ลงทะเบียน TestViewModel สำหรับระบบตรวจคุณภาพน้ำยาง
        ChangeNotifierProvider(create: (_) => TestViewModel()),
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
      title: 'Rubber Latex System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}