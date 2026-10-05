import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_car_dialog.dart';
import 'car_list_dialog.dart'; // 📌 เพิ่ม Import Dialog แสดงรายการรถ

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  List<dynamic> _farmers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
  }

  Future<void> _fetchFarmers() async {
    setState(() => _isLoading = true);
    final url = Uri.parse("http://127.0.0.1:3000/api/farmer/list");

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);

        if (resData['isError'] == false && resData['data'] is List) {
          setState(() {
            _farmers = resData['data'];
          });
        } else {
          setState(() => _farmers = []);
        }
      } else {
        setState(() => _farmers = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _farmers = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📌 ฟังก์ชันเปิด Dialog สำหรับลงทะเบียนรถใหม่
  void _openRegisterCarDialog(Map<String, dynamic> farmer) {
    showDialog(
      context: context,
      builder: (context) => RegisterCarDialog(
        farmerId: farmer['farmer_id'] ?? '',
        farmerName: farmer['farmer_name'] ?? '',
      ),
    );
  }

  // 📌 ฟังก์ชันเปิด Dialog สำหรับดูรายการรถของเกษตรกร
  void _openCarListDialog(Map<String, dynamic> farmer) {
    showDialog(
      context: context,
      builder: (context) => CarListDialog(
        farmerId: farmer['farmer_id'] ?? '',
        farmerName: farmer['farmer_name'] ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายชื่อเกษตรกร", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2538),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: _farmers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text("ไม่พบข้อมูลเกษตรกรในระบบ")),
                        )
                      : DataTable(
                          columns: const [
                            DataColumn(label: Text('รหัสเกษตรกร', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ชื่อ-นามสกุล', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('เบอร์โทรศัพท์', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('จัดการ', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _farmers.map<DataRow>((farmer) {
                            final farmerData = farmer as Map<String, dynamic>;
                            return DataRow(cells: [
                              DataCell(Text(farmerData['farmer_id']?.toString() ?? '')),
                              DataCell(Text(farmerData['farmer_name']?.toString() ?? '')),
                              DataCell(Text(farmerData['phone']?.toString() ?? '-')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 📌 ปุ่มดูรายการรถ (สีฟ้า)
                                    ElevatedButton.icon(
                                      onPressed: () => _openCarListDialog(farmerData),
                                      icon: const Icon(Icons.list_alt, size: 18),
                                      label: const Text("ดูรายการรถ"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 📌 ปุ่มลงทะเบียนรถเพิ่ม (สีเขียว)
                                    ElevatedButton.icon(
                                      onPressed: () => _openRegisterCarDialog(farmerData),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text("เพิ่มรถ"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                ),
              ),
            ),
    );
  }
}