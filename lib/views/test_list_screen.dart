import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../utils/result.dart';
import '../viewmodels/test_viewmodel.dart';
import 'quality_test_screen.dart';

class TestListScreen extends StatefulWidget {
  const TestListScreen({super.key});

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  final TestService _testService = TestService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลรายการตรวจ (พร้อมค้นหา)
  Future<void> _fetchRecords([String query = '']) async {
    setState(() => _isLoading = true);

    final result = await _testService.getTestsByFarmer(search: query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        switch (result) {
          case Ok(:final value):
            _records = value;
          case Error(:final error):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาด: ${error.toString()}')),
            );
        }
      });
    }
  }

  // 📌 ฟังก์ชันเปิด Dialog แก้ไขข้อมูล
  void _showEditDialog(Map<String, dynamic> item) {
    final ammoniaController =
        TextEditingController(text: item['ammonia']?.toString() ?? '');
    final vfaController =
        TextEditingController(text: item['vfa']?.toString() ?? '');
    final magnesiumController =
        TextEditingController(text: item['magnesium']?.toString() ?? '');
    final drcController =
        TextEditingController(text: item['drc']?.toString() ?? '');

    String selectedStatus = item['result_status'] ?? 'PASS';
    String selectedApprove = item['result_approve'] ?? 'PENDING';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('แก้ไขผลตรวจ (${item['purchase_id']})'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ammoniaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ammonia'),
                    ),
                    TextField(
                      controller: vfaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'VFA'),
                    ),
                    TextField(
                      controller: magnesiumController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Magnesium'),
                    ),
                    TextField(
                      controller: drcController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'DRC (%)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'สถานะผลตรวจ'),
                      items: const [
                        DropdownMenuItem(value: 'PASS', child: Text('PASS')),
                        DropdownMenuItem(value: 'FAIL', child: Text('FAIL')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final testId = item['test_id'];
                    if (testId == null) return;

                    final updatedRecord = TestRecord(
                      testId: testId,
                      purchaseId: item['purchase_id'],
                      ammonia: double.tryParse(ammoniaController.text),
                      vfa: double.tryParse(vfaController.text),
                      magnesium: double.tryParse(magnesiumController.text),
                      drc: double.tryParse(drcController.text),
                      resultStatus: selectedStatus,
                      resultApprove: selectedApprove,
                    );

                    final result =
                        await _testService.updateTest(testId, updatedRecord);

                    if (context.mounted) {
                      Navigator.pop(context);
                      _fetchRecords(_searchController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result is Ok
                              ? 'แก้ไขข้อมูลสำเร็จ'
                              : 'เกิดข้อผิดพลาดในการแก้ไข'),
                          backgroundColor:
                              result is Ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 📌 ฟังก์ชันยืนยันการลบข้อมูล
  void _confirmDelete(int testId, String farmerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบข้อมูล'),
        content: Text('คุณต้องการลบผลการตรวจของ "$farmerName" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final result = await _testService.deleteTest(testId);
              if (context.mounted) {
                Navigator.pop(context);
                _fetchRecords(_searchController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result is Ok
                        ? 'ลบรายการเรียบร้อย'
                        : 'เกิดข้อผิดพลาดในการลบ'),
                  ),
                );
              }
            },
            child: const Text('ลบข้อมูล', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการตรวจคุณภาพน้ำยาง'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QualityTestScreen()),
          );
          _fetchRecords(_searchController.text); // Refresh เมื่อบันทึกกลับมา
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มผลการตรวจ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 1. ช่องค้นหาเกษตรกร / รหัสรับซื้อ
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อ, รหัสเกษตรกร หรือรหัสรับซื้อ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchRecords('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (val) => _fetchRecords(val),
            ),
            const SizedBox(height: 16),

            // 📋 2. รายการตรวจคุณภาพ
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                      ? const Center(
                          child: Text(
                            'ไม่พบรายการตรวจคุณภาพน้ำยาง',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final item = _records[index];
                            final isPass = item['result_status'] == 'PASS';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: ชื่อเกษตรกร + Status + ปุ่ม Action (แก้ไข/ลบ)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '👨‍🌾 ${item['farmer_name'] ?? '-'} (${item['farmer_id'] ?? '-'})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isPass
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                item['result_status'] ?? 'N/A',
                                                style: TextStyle(
                                                  color: isPass
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue, size: 20),
                                              onPressed: () =>
                                                  _showEditDialog(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.grey, size: 20),
                                              onPressed: () => _confirmDelete(
                                                item['test_id'],
                                                item['farmer_name'] ?? '',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),

                                    // Sub-detail: รหัสรับซื้อ + น้ำหนัก + วันที่
                                    Text('รหัสรับซื้อ: ${item['purchase_id']}'),
                                    Text(
                                      'น้ำหนักยาง: ${item['rubber_weight'] ?? '-'} กก. | วันที่ตรวจ: ${item['test_date']}',
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 8),

                                    // Grid สารเคมี
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildChemInfo(
                                              'Ammonia', item['ammonia']),
                                          _buildChemInfo('VFA', item['vfa']),
                                          _buildChemInfo(
                                              'Magnesium', item['magnesium']),
                                          _buildChemInfo('DRC %', item['drc']),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChemInfo(String label, dynamic val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          val != null ? '$val' : '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}