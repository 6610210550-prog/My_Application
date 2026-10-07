import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../utils/result.dart';
import '../views/farmer_test_chart_widget.dart'; // 📌 Import กราฟ Widget
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

  int get _passCount => _records.where((e) => e['result_status'] == 'PASS').length;
  int get _failCount => _records.where((e) => e['result_status'] == 'FAIL').length;

  // 📊 ฟังก์ชันเปิด Modal แสดงกราฟ DRC แยกตามเกษตรกร
  void _showChartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<Result<List<FarmerTestSummaryModel>>>(
          future: _testService.getFarmerTestSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('ไม่สามารถโหลดข้อมูลสถิติได้')),
              );
            }

            final result = snapshot.data!;
            switch (result) {
              case Ok(:final value):
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.bar_chart, color: Color(0xFF0F766E)),
                          SizedBox(width: 8),
                          Text(
                            '📊 สรุป DRC เฉลี่ยแยกตามเกษตรกร',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      value.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('ไม่มีข้อมูลสถิติ'),
                            )
                          : FarmerTestChartWidget(summaryList: value),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              case Error():
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
                );
            }
          },
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final ammoniaController = TextEditingController(text: item['ammonia']?.toString() ?? '');
    final vfaController = TextEditingController(text: item['vfa']?.toString() ?? '');
    final magnesiumController = TextEditingController(text: item['magnesium']?.toString() ?? '');
    final drcController = TextEditingController(text: item['drc']?.toString() ?? '');

    String selectedStatus = item['result_status'] ?? 'PASS';
    String selectedApprove = item['result_approve'] ?? 'PENDING';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_note, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'แก้ไขผลตรวจ (${item['purchase_id'] ?? '-'})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(ammoniaController, 'Ammonia', Icons.science_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(vfaController, 'VFA', Icons.biotech_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(magnesiumController, 'Magnesium', Icons.grain),
                    const SizedBox(height: 12),
                    _buildTextField(drcController, 'DRC (%)', Icons.percent),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'สถานะผลตรวจ',
                        prefixIcon: Icon(Icons.verified, color: Colors.green.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PASS',
                          child: Text('PASS (ผ่านมาตรฐาน)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                        DropdownMenuItem(
                          value: 'FAIL',
                          child: Text('FAIL (ไม่ผ่าน)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
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
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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

                    final result = await _testService.updateTest(testId, updatedRecord);

                    if (context.mounted) {
                      Navigator.pop(context);
                      _fetchRecords(_searchController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result is Ok ? 'แก้ไขข้อมูลสำเร็จ' : 'เกิดข้อผิดพลาดในการแก้ไข'),
                          backgroundColor: result is Ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('บันทึก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.green.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _confirmDelete(int testId, String farmerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบข้อมูล'),
          ],
        ),
        content: Text('คุณต้องการลบผลการตรวจของ "$farmerName" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final result = await _testService.deleteTest(testId);
              if (context.mounted) {
                Navigator.pop(context);
                _fetchRecords(_searchController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result is Ok ? 'ลบรายการเรียบร้อย' : 'เกิดข้อผิดพลาดในการลบ'),
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          '🧪 รายการตรวจคุณภาพน้ำยาง',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 30, 40, 55),
        foregroundColor: Colors.white,
        // 📌 เพิ่มปุ่มดูกราฟบน AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            tooltip: 'ดูสถิติกราฟแยกตามเกษตรกร',
            onPressed: _showChartModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QualityTestScreen()),
          );
          _fetchRecords(_searchController.text);
        },
        backgroundColor: Colors.green.shade700,
        elevation: 3,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          'เพิ่มผลการตรวจ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          // 📊 1. การ์ดสรุปสถิติตัวเลข + ปุ่มกดเปิดกราฟ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard('ทั้งหมด', '${_records.length}', Colors.blue, Icons.list_alt)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('ผ่าน (PASS)', '$_passCount', Colors.green.shade600, Icons.check_circle_outline)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('ไม่ผ่าน (FAIL)', '$_failCount', Colors.red.shade600, Icons.highlight_off)),
                  ],
                ),
                const SizedBox(height: 8),
                // 📌 ปุ่มเด่นสำหรับกดดูสถิติกราฟ
                InkWell(
                  onTap: _showChartModal,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, color: Colors.teal.shade800, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'ดูสถิติกราฟสรุป DRC แยกตามเกษตรกร',
                          style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // 🔍 2. ช่องค้นหา
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อเกษตรกร, รหัส หรือรายการ...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchRecords('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
                        ),
                      ),
                      onChanged: (val) => _fetchRecords(val),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 📋 3. รายการตรวจคุณภาพ
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.green.shade700))
                        : _records.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    const Text('ไม่พบรายการตรวจคุณภาพน้ำยาง', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _records.length,
                                itemBuilder: (context, index) {
                                  final item = _records[index];
                                  final isPass = item['result_status'] == 'PASS';

                                  return Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                                    ),
                                    elevation: 1,
                                    shadowColor: Colors.black.withOpacity(0.04),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.person, color: Colors.green.shade700, size: 18),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            item['farmer_name'] ?? 'ไม่ระบุชื่อ',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '   รหัสเกษตรกร: ${item['farmer_id'] ?? '-'}',
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Status Badge
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isPass ? Colors.green.shade500 : Colors.red.shade500,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          isPass ? Icons.check_circle : Icons.cancel,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          item['result_status'] ?? 'N/A',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                                    onSelected: (val) {
                                                      if (val == 'edit') _showEditDialog(item);
                                                      if (val == 'delete') _confirmDelete(item['test_id'], item['farmer_name'] ?? '');
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 18), SizedBox(width: 8), Text('แก้ไข')]),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('ลบ')]),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          Divider(height: 16, color: Colors.grey.shade200),

                                          // รายละเอียด รหัสรับซื้อ
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('📦 รหัสรับซื้อ: ${item['purchase_id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                                              Text('⚖️ ${item['rubber_weight'] ?? '-'} กก.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800)),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('📅 วันที่ตรวจ: ${item['test_date'] ?? '-'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),

                                          const SizedBox(height: 10),

                                          // 🧪 Grid ค่าสารเคมี
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                _buildChemBadge('Ammonia', item['ammonia'], Colors.purple.shade700, Colors.purple.shade50),
                                                _buildChemBadge('VFA', item['vfa'], Colors.orange.shade800, Colors.orange.shade50),
                                                _buildChemBadge('Magnesium', item['magnesium'], Colors.blue.shade700, Colors.blue.shade50),
                                                _buildChemBadge('DRC (%)', item['drc'], Colors.green.shade800, Colors.green.shade50, isHighlight: true),
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
          ),
        ],
      ),
    );
  }

  // 📌 Widget การ์ดสถิติตัวเลข
  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // 📌 Widget แสดงค่าสารเคมี
  Widget _buildChemBadge(String label, dynamic val, Color textColor, Color bgColor, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            val != null ? '$val' : '-',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 14 : 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}