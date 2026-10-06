// lib/car_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarListDialog extends StatefulWidget {
  final String farmerId;
  final String farmerName;

  const CarListDialog({
    super.key,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  State<CarListDialog> createState() => _CarListDialogState();
}

class _CarListDialogState extends State<CarListDialog> {
  List<dynamic> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  // ดึงข้อมูลรายการรถ
  Future<void> _fetchCars() async {
    setState(() => _isLoading = true);
    final url = Uri.parse("http://127.0.0.1:3000/api/car/list/${widget.farmerId}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['isError'] == false && resData['data'] is List) {
          setState(() {
            _cars = resData['data'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลรถ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันลบข้อมูลรถผ่าน API
  Future<void> _deleteCar(String carId, String carNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบรถ"),
        content: Text("คุณต้องการลบรถทะเบียน $carNumber หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ลบข้อมูล", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse("http://127.0.0.1:3000/api/car/delete/$carId");
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ลบรถทะเบียน $carNumber เรียบร้อย'), backgroundColor: Colors.green),
          );
        }
        _fetchCars(); // ดึงข้อมูลรายการรถใหม่หลังลบสำเร็จ
      } else {
        throw Exception('ไม่สามารถลบข้อมูลได้');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("รายการรถ - ${widget.farmerName} (${widget.farmerId})"),
      content: SizedBox(
        width: 650,
        child: _isLoading
            ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
            : _cars.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text("ยังไม่มีข้อมูลรถที่ลงทะเบียนไว้")),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ทะเบียนรถ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ประเภทรถ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('จังหวัด', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('สี', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('จัดการ', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _cars.map<DataRow>((car) {
                        final carData = car as Map<String, dynamic>;
                        final carId = carData['car_id']?.toString() ?? carData['id']?.toString() ?? '';
                        final carNumber = carData['car_number']?.toString() ?? '-';

                        return DataRow(cells: [
                          DataCell(Text(carNumber)),
                          DataCell(Text(carData['cartype_name']?.toString() ?? '-')),
                          DataCell(Text(carData['province']?.toString() ?? '-')),
                          DataCell(Text(carData['color']?.toString() ?? '-')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteCar(carId, carNumber),
                              tooltip: 'ลบรถ',
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ปิด"),
        ),
      ],
    );
  }
}