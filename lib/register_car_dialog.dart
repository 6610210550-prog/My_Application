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

  // 📌 ค่าประเภทรถเดิม (1: รถบรรทุก, 2: รถกระบะ, 3: รถหกล้อ, 4: รถสิบล้อ)
  int _selectedCarTypeId = 1;
  final List<Map<String, dynamic>> _carTypes = [
    {'id': 1, 'name': 'รถบรรทุก'},
    {'id': 2, 'name': 'รถกระบะ'},
    {'id': 3, 'name': 'รถหกล้อ'},
    {'id': 4, 'name': 'รถสิบล้อ'},
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _carNumberController.dispose();
    _colorController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _submitCarForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final url = Uri.parse("http://127.0.0.1:3000/api/car/register");

    final bodyData = {
      "car_number": _carNumberController.text.trim(),
      "farmer_id": widget.farmerId,
      "color": _colorController.text.trim(),
      "province": _provinceController.text.trim(),
      "cartype_id": _selectedCarTypeId,
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
            SnackBar(
              content: Text(resData['data'] ?? 'ลงทะเบียนรถเรียบร้อย'),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึก'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎨 Helper ตกแต่ง Input Field ให้สวยงามสมส่วน
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF0F766E)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📌 Header Bar พร้อม Badge ชื่อและรหัสเกษตรกรแบบโดดเด่น
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Color(0xFF0F766E),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ลงทะเบียนรถคันใหม่',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          // 🏷️ ป้ายชื่อและรหัสเกษตรกร (ปรับเน้นให้โดดเด่น สบายตา)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1), // สีเขียวมิ้นต์พาสเทล
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF99F6E4)),
                            ),
                            child: Text(
                              '${widget.farmerName}  ID : ${widget.farmerId}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF0F766E), // สีเขียวเข้มอ่านง่าย
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 20),

                // 1. ทะเบียนรถ
                TextFormField(
                  controller: _carNumberController,
                  decoration: _buildInputDecoration(
                    labelText: 'ทะเบียนรถ',
                    hintText: 'เช่น กข 1234',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
                ),
                const SizedBox(height: 16),

                // 2. ประเภทรถ
                DropdownButtonFormField<int>(
                  value: _selectedCarTypeId,
                  decoration: _buildInputDecoration(
                    labelText: 'ประเภทรถ',
                    prefixIcon: Icons.local_shipping_outlined,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  items: _carTypes.map((type) {
                    return DropdownMenuItem<int>(
                      value: type['id'] as int,
                      child: Text(
                        type['name'] as String,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCarTypeId = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 3. จังหวัด
                TextFormField(
                  controller: _provinceController,
                  decoration: _buildInputDecoration(
                    labelText: 'จังหวัด',
                    hintText: 'เช่น สงขลา',
                    prefixIcon: Icons.location_city_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // 4. สีรถ
                TextFormField(
                  controller: _colorController,
                  decoration: _buildInputDecoration(
                    labelText: 'สีรถ',
                    hintText: 'เช่น ขาว , ดำ , แดง',
                    prefixIcon: Icons.palette_outlined,
                  ),
                ),

                const SizedBox(height: 28),

                // 📌 ปุ่มจัดการ (ยกเลิก / บันทึกข้อมูล)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitCarForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'บันทึกข้อมูลรถ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}