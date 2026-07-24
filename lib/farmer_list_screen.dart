import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'register_farmer_screen.dart';
import 'register_vehicle_screen.dart';
import 'latex_purchase_screen.dart';
import 'daily_price_screen.dart';

class FarmerListScreen extends StatelessWidget {
  const FarmerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      
      // 1. AppBar หัวข้อด้านบน
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2538),
        elevation: 0,
        title: const Text(
          "รายชื่อเกษตรกร",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // 2. เมนูด้านข้าง (Drawer)
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1E2538),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF181D2D)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/tar.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.business,
                            size: 40,
                            color: Color(0xFF2E6D52),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "บริษัท พัทลุงพาราเท็กซ์ จำกัด",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    ListTile(
                      leading: const Text("🏡", style: TextStyle(fontSize: 22)),
                      title: const Text("หน้าหลัก", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                      },
                    ),
                    ListTile(
                      leading: const Text("➕", style: TextStyle(fontSize: 22)),
                      title: const Text("ลงทะเบียนเกษตรกร", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterFarmerScreen()));
                      },
                    ),
                    // หน้านี้คือ "รายชื่อเกษตรกร" ทำไฮไลต์เมนูนี้
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6D52).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Text("📋", style: TextStyle(fontSize: 22)),
                        title: const Text("รายชื่อเกษตรกร", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    ListTile(
                      leading: const Text("🚗", style: TextStyle(fontSize: 22)),
                      title: const Text("ลงทะเบียนรถ", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterVehicleScreen()));
                      },
                    ),
                    ListTile(
                      leading: const Text("💧", style: TextStyle(fontSize: 22)),
                      title: const Text("บันทึกรับซื้อน้ำยาง", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LatexPurchaseScreen()));
                      },
                    ),
                    ListTile(
                      leading: const Text("💰", style: TextStyle(fontSize: 22)),
                      title: const Text("ตั้งราคาประจำวัน", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DailyPriceScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 3. เนื้อหาภายในหน้า
      body: const Center(
        child: Text(
          "หน้ารายชื่อเกษตรกร",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2538)),
        ),
      ),
    );
  }
}