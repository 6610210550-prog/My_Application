import 'package:flutter/material.dart';

class RegisterVehicleScreen extends StatelessWidget {
  const RegisterVehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลงทะเบียนรถ")),
      body: const Center(child: Text("หน้าลงทะเบียนรถ")),
    );
  }
}