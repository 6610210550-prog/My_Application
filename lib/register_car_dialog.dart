import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterCarDialog extends StatefulWidget {
  final String farmerId;
  final String farmerName;

  const RegisterCarDialog({
    super.key,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  State<RegisterCarDialog> createState() => _RegisterCarDialogState();
}

class _RegisterCarDialogState extends State<RegisterCarDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();

  // 📌 1. ตัวแปรเก็บค่าประเภทรถที่เลือก (ค่าเริ่มต้น = 1 รถบรรทุก)
  int _selectedCarTypeId = 1;

  // 📌 รายการประเภทรถสำหรับ Dropdown
  final List<Map<String, dynamic>> _carTypes = [
    {'id': 1, 'name': 'รถบรรทุก'},
    {'id': 2, 'name': 'รถกระบะ'},
    {'id': 3, 'name': 'รถหกล้อ'},
    {'id': 4, 'name': 'รถสิบล้อ'},
  ];

  bool _isLoading = false;

  Future<void> _submitCarForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final url = Uri.parse("http://127.0.0.1:3000/api/car/register");

    final bodyData = {
      "car_number": _carNumberController.text.trim(),
      "farmer_id": widget.farmerId,
      "color": _colorController.text.trim(),
      "province": _provinceController.text.trim(),
      "cartype_id": _selectedCarTypeId, // 📌 2. ส่งค่าประเภทรถที่เลือกไปที่ API
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(bodyData),
      );

      final resData = json.decode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && resData['isError'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['data']), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // ปิด Dialog
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['errorMessage']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("ลงทะเบียนรถ - ${widget.farmerName} (${widget.farmerId})"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _carNumberController,
                decoration: const InputDecoration(labelText: 'ทะเบียนรถ * (เช่น กข 1234)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
              ),
              const SizedBox(height: 12),
              
              // 📌 3. เพิ่ม Widget Dropdown ให้ผู้ใช้กดเลือกประเภทรถ
              DropdownButtonFormField<int>(
                value: _selectedCarTypeId,
                decoration: const InputDecoration(
                  labelText: 'ประเภทรถ *',
                ),
                items: _carTypes.map((type) {
                  return DropdownMenuItem<int>(
                    value: type['id'] as int,
                    child: Text(type['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCarTypeId = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(labelText: 'จังหวัด'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'สีรถ'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ยกเลิก"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitCarForm,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6D52)),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("บันทึกข้อมูลรถ", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}