import 'package:flutter/material.dart';

class DailyPriceScreen extends StatelessWidget {
  const DailyPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ตั้งราคาประจำวัน")),
      body: const Center(child: Text("หน้าตั้งราคาประจำวัน")),
    );
  }
}