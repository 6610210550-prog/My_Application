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
  bool _isFetching = true; // สถานะตอนโหลดราคาของวันนี้

  // URL สำหรับยิง API (ปรับ IP ให้ตรงกับ Backend ของคุณ)
  final String _saveApiUrl = "http://127.0.0.1:3000/api/price/save_price";
  final String _getTodayPriceApiUrl = "http://127.0.0.1:3000/api/price/get_today_price";

  @override
  void initState() {
    super.initState();
    _fetchTodayPrice(); // ดึงราคาประจำวันเมื่อเปิดหน้าแอป
  }

  @override
  void dispose() {
    _buyPriceController.dispose();
    super.dispose();
  }

  // ฟังก์ชันดึงราคาของวันนี้จาก Backend
  Future<void> _fetchTodayPrice() async {
    try {
      final response = await http.get(Uri.parse(_getTodayPriceApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isError'] == false && data['data'] != null) {
          setState(() {
            // ดึงราคาเดิมมาใส่ใน TextField
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

  // ฟังก์ชันบันทึกการตั้งราคา
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
          _showSnackBar("บันทึกราคารับซื้อเรียบร้อยแล้ว", Colors.green);
          _fetchTodayPrice(); // ดึงข้อมูลใหม่อีกครั้งเพื่อยืนยัน
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
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String todayString = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("ตั้งราคารับซื้อน้ำยางพารา"),
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // การ์ดแสดงวันที่ปัจจุบัน
                    Card(
                      elevation: 0,
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.green),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ตั้งราคาประจำวันที่",
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  todayString,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ช่องกรอกราคารับซื้อ
                    const Text(
                      "ราคารับซื้อน้ำยาง (บาท / กิโลกรัม)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _buyPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: "บาท",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                    const SizedBox(height: 32),

                    // ปุ่มบันทึกข้อมูล
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBuyPrice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "บันทึกราคารับซื้อ",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}