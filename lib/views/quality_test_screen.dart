import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../utils/result.dart';

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

  Future<void> _fetchPendingPurchases() async {
    setState(() => _isFetching = true);

    try {
      final result = await _testService.getPendingPurchases();

      if (mounted) {
        setState(() {
          _isFetching = false;
          switch (result) {
            case Ok(:final value):
              _pendingList = value;
            case Error(:final error):
              _showSnackBar(
                error.toString().replaceAll('Exception: ', ''),
                Colors.redAccent,
              );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetching = false);
        _showSnackBar('เกิดข้อผิดพลาดในการดึงข้อมูล: $e', Colors.redAccent);
      }
    }
  }

  Future<void> _saveTestResult() async {
    if (_selectedPurchase == null) {
      _showSnackBar('กรุณาเลือกรายการรับซื้อก่อน', Colors.orange.shade800);
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
            _showSnackBar('บันทึกผลการตรวจคุณภาพเรียบร้อยแล้ว', const Color(0xFF0D9488));
            _resetForm();
            _fetchPendingPurchases();
          case Error(:final error):
            _showSnackBar(
              error.toString().replaceAll('Exception: ', ''),
              Colors.redAccent,
            );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('เกิดข้อผิดพลาดในการบันทึก: $e', Colors.redAccent);
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
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'บันทึกการตรวจคุณภาพน้ำยาง',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 30, 40, 55), // Teal Theme
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingPurchases,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: _isFetching
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F766E)),
                  SizedBox(height: 16),
                  Text('กำลังโหลดรายการน้ำยาง...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 Section 1: เลือกรายการรับซื้อ
                    _buildSectionHeader(
                      icon: Icons.assignment_outlined,
                      title: 'รายการรับซื้อที่รอตรวจ',
                    ),
                    const SizedBox(height: 10),

                    if (_pendingList.isEmpty)
                      _buildEmptyState()
                    else
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<PendingPurchase>(
                              value: _selectedPurchase,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(Icons.water_drop, color: Color(0xFF0F766E)),
                              ),
                              hint: const Text('---- เลือกรายการรับซื้อ ----'),
                              items: _pendingList.map((purchase) {
                                return DropdownMenuItem<PendingPurchase>(
                                  value: purchase,
                                  child: Text(
                                    '#${purchase.purchaseId} - ${purchase.farmerName} (${purchase.rubberWeight} กก.)',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // 📌 Section 2: รายละเอียดและฟอร์มตรวจเคมี
                    if (_selectedPurchase != null) ...[
                      // การ์ดแสดงรายละเอียดเกษตรกรที่เลือก
                      _buildFarmerInfoCard(_selectedPurchase!),

                      const SizedBox(height: 20),

                      _buildSectionHeader(
                        icon: Icons.science_outlined,
                        title: 'กรอกค่าผลตรวจทางเคมี',
                      ),
                      const SizedBox(height: 12),

                      _buildNumberField(
                        label: 'ค่าแอมโมเนีย (Ammonia)',
                        controller: _ammoniaController,
                        unit: '%',
                        icon: Icons.biotech,
                      ),
                      _buildNumberField(
                        label: 'ค่า VFA',
                        controller: _vfaController,
                        unit: 'vfa',
                        icon: Icons.pie_chart_outline,
                      ),
                      _buildNumberField(
                        label: 'ค่าแมกนีเซียม (Magnesium)',
                        controller: _magnesiumController,
                        unit: 'ppm',
                        icon: Icons.device_thermostat,
                      ),
                      _buildNumberField(
                        label: 'ค่า DRC (%)',
                        controller: _drcController,
                        unit: '%',
                        icon: Icons.percent,
                      ),

                      const SizedBox(height: 16),

                      // 📌 Section 3: สรุปผลและอนุมัติ
                      _buildSectionHeader(
                        icon: Icons.fact_check_outlined,
                        title: 'สรุปผลการประเมิน',
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownContainer(
                              label: 'ผลการตรวจ',
                              child: DropdownButton<String>(
                                value: _resultStatus,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'PASS',
                                    child: Text('✅ ผ่าน (PASS)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'FAIL',
                                    child: Text('❌ ไม่ผ่าน (FAIL)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                onChanged: (val) => setState(() => _resultStatus = val!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownContainer(
                              label: 'การอนุมัติ',
                              child: DropdownButton<String>(
                                value: _resultApprove,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 'PENDING', child: Text('⏳ รออนุมัติ')),
                                  DropdownMenuItem(value: 'APPROVED', child: Text('🟢 อนุมัติแล้ว')),
                                  DropdownMenuItem(value: 'REJECTED', child: Text('🔴 ปฏิเสธ')),
                                ],
                                onChanged: (val) => setState(() => _resultApprove = val!),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 📌 ปุ่มบันทึก
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveTestResult,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _isSaving ? 'กำลังบันทึก...' : 'บันทึกผลการตรวจคุณภาพ',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F766E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 40, color: Colors.amber.shade700),
          const SizedBox(height: 8),
          Text(
            'ไม่มีรายการน้ำยางที่รอตรวจคุณภาพ',
            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInfoCard(PendingPurchase purchase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รหัสการรับซื้อ: #${purchase.purchaseId}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${purchase.rubberWeight} กก.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text('ชื่อเกษตรกร: ${purchase.farmerName}', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          suffixText: unit,
          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          child,
        ],
      ),
    );
  }
}