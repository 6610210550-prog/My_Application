import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services & Repositories
import 'services/purchase_service.dart';
import 'repositories/purchase_repository.dart';

// ViewModels
import 'viewmodels/purchase_viewmodel.dart';

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

        // 2. ลงทะเบียน ViewModel สำหรับจัดการ State และคำนวณราคา Real-time
        ChangeNotifierProxyProvider<PurchaseRepository, PurchaseViewModel>(
          create: (context) => PurchaseViewModel(
            repository: context.read<PurchaseRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? PurchaseViewModel(repository: repository),
        ),
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
      // คุณสามารถเลือกหน้าเริ่มต้นได้:
      // Option A: เปิดไปที่ LoginScreen ตามเดิมของคุณ
      home: const LoginScreen(),

      // Option B: หรือหากต้องการทดสอบหน้าบันทึกรับซื้อน้ำยางพาราโดยตรง ให้เปลี่ยน home เป็น:
      // home: const PurchaseScreen(
      //   todayPrice: 55.0,
      //   priceId: '2026-10-05',
      // ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}