import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DailyPriceScreen extends StatefulWidget {
  const DailyPriceScreen({super.key});

  @override
  State<DailyPriceScreen> createState() => _DailyPriceScreenState();
}

class _DailyPriceScreenState extends State<DailyPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _buyPriceController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  final String _saveApiUrl = "http://127.0.0.1:3000/api/price/save_price";
  final String _getTodayPriceApiUrl = "http://127.0.0.1:3000/api/price/get_today_price";

  @override
  void initState() {
    super.initState();
    _fetchTodayPrice();
  }

  @override
  void dispose() {
    _buyPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayPrice() async {
    try {
      final response = await http.get(Uri.parse(_getTodayPriceApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isError'] == false && data['data'] != null) {
          setState(() {
            _buyPriceController.text = data['data']['buy_price'].toString();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching price: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  Future<void> _saveBuyPrice() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_saveApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "buy_price": double.parse(_buyPriceController.text),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['isError'] == false) {
          _showSnackBar("บันทึกราคารับซื้อเรียบร้อยแล้ว", const Color(0xFF0D9488));
          _fetchTodayPrice();
        } else {
          _showSnackBar(data['errorMessage'] ?? "เกิดข้อผิดพลาดในการบันทึก", Colors.red);
        }
      } else {
        _showSnackBar("เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${response.statusCode})", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("เกิดข้อผิดพลาด: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w600),
      prefixIcon: Icon(prefixIcon, size: 22, color: const Color(0xFF0F766E)),
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String todayString = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2837),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "ตั้งราคารับซื้อน้ำยางพารา",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📅 การ์ดแสดงวันที่ปัจจุบัน
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0F766E), size: 26),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ตั้งราคาประจำวันที่",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                todayString,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 💵 การ์ดฟอร์มกำหนดราคา
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ราคารับซื้อน้ำยางสด",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "ระบุราคารับซื้อประจำวันเพื่อใช้คำนวณในระบบ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _buyPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _buildInputDecoration(
                              labelText: "ราคารับซื้อ (บาท / กิโลกรัม)",
                              prefixIcon: Icons.payments_outlined,
                              suffixText: "บาท",
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกราคารับซื้อ';
                              }
                              if (double.tryParse(value) == null) {
                                return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                              }
                              if (double.parse(value) <= 0) {
                                return 'ราคาต้องมากกว่า 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveBuyPrice,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        
                                        SizedBox(width: 8),
                                        Text(
                                          "บันทึกราคารับซื้อ",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}