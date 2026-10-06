import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../utils/result.dart'; // 📌 1. Import Result เพื่อใช้งาน Sealed Class Pattern

class QualityTestScreen extends StatefulWidget {
  const QualityTestScreen({super.key});

  @override
  State<QualityTestScreen> createState() => _QualityTestScreenState();
}

class _QualityTestScreenState extends State<QualityTestScreen> {
  final TestService _testService = TestService();
  final _formKey = GlobalKey<FormState>();

  List<PendingPurchase> _pendingList = [];
  PendingPurchase? _selectedPurchase;

  final TextEditingController _ammoniaController = TextEditingController();
  final TextEditingController _vfaController = TextEditingController();
  final TextEditingController _magnesiumController = TextEditingController();
  final TextEditingController _drcController = TextEditingController();

  String _resultStatus = 'PASS';
  String _resultApprove = 'PENDING';
  bool _isFetching = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingPurchases();
  }

  @override
  void dispose() {
    _ammoniaController.dispose();
    _vfaController.dispose();
    _magnesiumController.dispose();
    _drcController.dispose();
    super.dispose();
  }

  // 📌 1. ดึงรายการรอตรวจ
  Future<void> _fetchPendingPurchases() async {
    setState(() => _isFetching = true);

    try {
      final result = await _testService.getPendingPurchases();

      if (mounted) {
        setState(() {
          _isFetching = false;
          
          // ใช้ Pattern Matching ถอดค่าจาก Result<T> อย่างปลอดภัย
          switch (result) {
            case Ok(:final value):
              _pendingList = value;
            case Error(:final error):
              _showSnackBar(
                error.toString().replaceAll('Exception: ', ''), 
                Colors.red
              );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetching = false);
        _showSnackBar('เกิดข้อผิดพลาดในการดึงข้อมูล: $e', Colors.red);
      }
    }
  }

  // 📌 2. บันทึกผลตรวจ
  Future<void> _saveTestResult() async {
    if (_selectedPurchase == null) {
      _showSnackBar('กรุณาเลือกรายการรับซื้อก่อน', Colors.orange);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final record = TestRecord(
        purchaseId: _selectedPurchase!.purchaseId,
        ammonia: double.tryParse(_ammoniaController.text),
        vfa: double.tryParse(_vfaController.text),
        magnesium: double.tryParse(_magnesiumController.text),
        drc: double.tryParse(_drcController.text),
        resultStatus: _resultStatus,
        resultApprove: _resultApprove,
      );

      final result = await _testService.saveTest(record);

      if (mounted) {
        setState(() => _isSaving = false);

        switch (result) {
          case Ok():
            _showSnackBar('บันทึกผลการตรวจคุณภาพเรียบร้อยแล้ว', Colors.green);
            _resetForm();
            _fetchPendingPurchases();
          case Error(:final error):
            _showSnackBar(
              error.toString().replaceAll('Exception: ', ''), 
              Colors.red
            );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('เกิดข้อผิดพลาดในการบันทึก: $e', Colors.red);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedPurchase = null;
      _ammoniaController.clear();
      _vfaController.clear();
      _magnesiumController.clear();
      _drcController.clear();
      _resultStatus = 'PASS';
      _resultApprove = 'PENDING';
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกการตรวจคุณภาพน้ำยาง'),
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 1. Dropdown เลือกรายการรับซื้อ
                    const Text(
                      'เลือกรายการรับซื้อที่ต้องการตรวจ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    _pendingList.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: const Text(
                              'ไม่มีรายการน้ำยางที่รอตรวจคุณภาพ',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : DropdownButtonFormField<PendingPurchase>(
                            initialValue: _selectedPurchase,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            hint: const Text('---- เลือกรายการรับซื้อ ----'),
                            items: _pendingList.map((purchase) {
                              return DropdownMenuItem<PendingPurchase>(
                                value: purchase,
                                child: Text(
                                  'ID: ${purchase.purchaseId} - ${purchase.farmerName} (${purchase.rubberWeight} กก.)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPurchase = val;
                                if (val != null) {
                                  _drcController.text = val.purchaseDrc?.toString() ?? '';
                                }
                              });
                            },
                          ),
                    const SizedBox(height: 20),

                    // 📌 2. ฟอร์มกรอกค่าทางเคมี
                    if (_selectedPurchase != null) ...[
                      Card(
                        elevation: 0,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('รหัสรับซื้อ: ${_selectedPurchase!.purchaseId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('ชื่อเกษตรกร: ${_selectedPurchase!.farmerName}'),
                              Text('น้ำหนักยาง: ${_selectedPurchase!.rubberWeight} กก.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildNumberField('ค่าแอมโมเนีย (Ammonia)', _ammoniaController),
                      _buildNumberField('ค่า VFA', _vfaController),
                      _buildNumberField('ค่าแมกนีเซียม (Magnesium)', _magnesiumController),
                      _buildNumberField('ค่า DRC (%)', _drcController),

                      const SizedBox(height: 16),

                      // 📌 3. สถานะผลการตรวจ
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _resultStatus,
                              decoration: const InputDecoration(labelText: 'ผลการตรวจ (Status)'),
                              items: const [
                                DropdownMenuItem(value: 'PASS', child: Text('ผ่าน (PASS)')),
                                DropdownMenuItem(value: 'FAIL', child: Text('ไม่ผ่าน (FAIL)')),
                              ],
                              onChanged: (val) => setState(() => _resultStatus = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _resultApprove,
                              decoration: const InputDecoration(labelText: 'การอนุมัติ (Approve)'),
                              items: const [
                                DropdownMenuItem(value: 'PENDING', child: Text('รออนุมัติ')),
                                DropdownMenuItem(value: 'APPROVED', child: Text('อนุมัติแล้ว')),
                                DropdownMenuItem(value: 'REJECTED', child: Text('ปฏิเสธ')),
                              ],
                              onChanged: (val) => setState(() => _resultApprove = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 📌 4. ปุ่มบันทึก
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveTestResult,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('บันทึกผลการตรวจคุณภาพ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}