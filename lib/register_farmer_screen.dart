import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterFarmerScreen extends StatefulWidget {
  const RegisterFarmerScreen({super.key});

  @override
  State<RegisterFarmerScreen> createState() => _RegisterFarmerScreenState();
}

class _RegisterFarmerScreenState extends State<RegisterFarmerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller สำหรับฟิลด์ข้อมูล (ตั้งค่าเริ่มต้นให้ farmer_id เป็น read-only)
  final TextEditingController _farmerIdController =
      TextEditingController(text: "ระบบสร้างให้อัตโนมัติ (FM...)");
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bankNumberController = TextEditingController();

  // Controller สำหรับส่วนของที่อยู่
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _soiController = TextEditingController();
  final TextEditingController _roadController = TextEditingController();
  final TextEditingController _subDistrictController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();

  String? _selectedBank;
  final List<String> _bankList = [
    'กรุงไทย',
    'กสิกรไทย',
    'ไทยพาณิชย์',
    'กรุงเทพ',
    'กรุงศรีอยุธยา',
    'ออมสิน',
    'ธ.ก.ส.',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _farmerIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bankNumberController.dispose();
    _houseNoController.dispose();
    _soiController.dispose();
    _roadController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  // รวมที่อยู่อยู่ในรูปแบบข้อความยาวเพื่อบันทึกลงฟิลด์ address
  String _buildFullAddress() {
    List<String> parts = [];
    if (_houseNoController.text.trim().isNotEmpty) parts.add(_houseNoController.text.trim());
    if (_soiController.text.trim().isNotEmpty) parts.add("ซ.${_soiController.text.trim()}");
    if (_roadController.text.trim().isNotEmpty) parts.add("ถ.${_roadController.text.trim()}");
    if (_subDistrictController.text.trim().isNotEmpty) parts.add("ต.${_subDistrictController.text.trim()}");
    if (_districtController.text.trim().isNotEmpty) parts.add("อ.${_districtController.text.trim()}");
    if (_provinceController.text.trim().isNotEmpty) parts.add("จ.${_provinceController.text.trim()}");
    if (_zipcodeController.text.trim().isNotEmpty) parts.add(_zipcodeController.text.trim());
    return parts.join(" ");
  }

  // ฟังก์ชันยิง API บันทึกข้อมูล
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 💡 หมายเหตุเรื่อง URL:
    // - หากรันบน Chrome / Edge ให้ใช้ 'http://127.0.0.1:3000/api/farmer/register'
    // - หากรันบน Android Emulator ให้เปลี่ยน 127.0.0.1 เป็น 10.0.2.2
    final url = Uri.parse("http://127.0.0.1:3000/api/farmer/register");

    // ❌ ไม่ต้องส่ง farmer_id แล้ว Backend จะเป็นผู้สร้างให้อัตโนมัติ
    final bodyData = {
      "farmer_name": _nameController.text.trim(),
      "address": _buildFullAddress(),
      "phone": _phoneController.text.trim(),
      "bank_number": _bankNumberController.text.trim(),
      "bank_type": _selectedBank ?? "",
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
              content: Text(resData['data'] ?? 'ลงทะเบียนเกษตรกรเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // ปิดหน้าต่างเมื่อบันทึกสำเร็จ
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึก'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("ลงทะเบียนเกษตรกร", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E2538),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "รหัสเกษตรกร (สร้างให้อัตโนมัติ)",
                          hint: "FM000000001",
                          icon: Icons.badge_outlined,
                          controller: _farmerIdController,
                          readOnly: true, // 🔒 ล็อกไม่ให้ผู้ใช้แก้ไข
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFormField(
                          label: "ชื่อ-นามสกุล *",
                          hint: "ระบุชื่อและนามสกุล",
                          icon: Icons.person_outline,
                          controller: _nameController,
                          maxLength: 100,
                          validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildFormField(
                    label: "เบอร์โทรศัพท์",
                    hint: "08x-xxx-xxxx",
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(icon: Icons.location_on_outlined, title: "ที่อยู่ปัจจุบัน"),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "บ้านเลขที่ / หมู่",
                          hint: "เช่น 123/4 หมู่ 2",
                          icon: Icons.home_outlined,
                          controller: _houseNoController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFormField(
                          label: "ตรอก / ซอย",
                          hint: "เช่น สุขใจ",
                          icon: Icons.near_me_outlined,
                          controller: _soiController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "ถนน",
                          hint: "เช่น มิตรภาพ",
                          icon: Icons.map_outlined,
                          controller: _roadController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFormField(
                          label: "ตำบล / แขวง",
                          hint: "เช่น คอหงส์",
                          icon: Icons.location_city_outlined,
                          controller: _subDistrictController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "อำเภอ / เขต",
                          hint: "เช่น หาดใหญ่",
                          icon: Icons.domain_outlined,
                          controller: _districtController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFormField(
                          label: "จังหวัด",
                          hint: "เช่น สงขลา",
                          icon: Icons.public_outlined,
                          controller: _provinceController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "รหัสไปรษณีย์",
                          hint: "เช่น 90110",
                          icon: Icons.mail_outline,
                          controller: _zipcodeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(icon: Icons.credit_card_outlined, title: "ข้อมูลบัญชีธนาคารสำหรับรับเงิน"),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "เลขที่บัญชีธนาคาร",
                          hint: "ระบุเลขบัญชีสำหรับโอนเงิน",
                          icon: Icons.payment_outlined,
                          controller: _bankNumberController,
                          keyboardType: TextInputType.number,
                          maxLength: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBankDropdown(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E6D52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "บันทึกข้อมูลเกษตรกร",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFFE2E8F0), thickness: 1),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool readOnly = false, // 📌 เพิ่มตัวแปรสำหรับควบคุมการแก้ไข
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          readOnly: readOnly, // 📌 กำหนดสถานะ readOnly
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          validator: validator,
          style: readOnly
              ? const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)
              : const TextStyle(color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC), // เปลี่ยนสีพื้นหลังกรณีอ่านอย่างเดียว
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFF10B981),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ชื่อธนาคาร",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedBank,
          hint: const Text("-- กรุณาเลือกธนาคาร --", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.account_balance_outlined, color: Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
          items: _bankList.map((String bank) {
            return DropdownMenuItem<String>(
              value: bank,
              child: Text(bank, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedBank = newValue;
            });
          },
        ),
      ],
    );
  }
}