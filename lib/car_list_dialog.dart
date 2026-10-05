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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("รายการรถ - ${widget.farmerName} (${widget.farmerId})"),
      content: SizedBox(
        width: 600,
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
                      ],
                      rows: _cars.map<DataRow>((car) {
                        final carData = car as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(carData['car_number']?.toString() ?? '-')),
                          DataCell(Text(carData['cartype_name']?.toString() ?? '-')),
                          DataCell(Text(carData['province']?.toString() ?? '-')),
                          DataCell(Text(carData['color']?.toString() ?? '-')),
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