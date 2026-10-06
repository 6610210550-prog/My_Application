import 'package:flutter/material.dart';
import '../services/test_service.dart';
import '../utils/result.dart';

class FarmerReportScreen extends StatefulWidget {
  const FarmerReportScreen({super.key});

  @override
  State<FarmerReportScreen> createState() => _FarmerReportScreenState();
}

class _FarmerReportScreenState extends State<FarmerReportScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการตรวจแยกตามเกษตรกร'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 📌 1. ช่อง Search Bar
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
              onChanged: (val) {
                _fetchRecords(val);
              },
            ),
            const SizedBox(height: 16),

            // 📌 2. แสดงรายการประวัติการตรวจ
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                      ? const Center(
                          child: Text(
                            'ไม่พบข้อมูลรายการตรวจคุณภาพ',
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
                                    // Header: ชื่อเกษตรกร + Status Badge
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '👨‍🌾 ${item['farmer_name']} (${item['farmer_id']})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
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
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Detail: รหัสรับซื้อ + วันที่ + น้ำหนัก
                                    Text('รหัสรับซื้อ: ${item['purchase_id']}'),
                                    Text(
                                      'น้ำหนักยาง: ${item['rubber_weight']} กก. | วันที่ตรวจ: ${item['test_date']}',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 8),

                                    // Chemical Stats Grid
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
                                          _buildChemInfo('Ammonia', item['ammonia']),
                                          _buildChemInfo('VFA', item['vfa']),
                                          _buildChemInfo('Magnesium', item['magnesium']),
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