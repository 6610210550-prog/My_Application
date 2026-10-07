import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
import '../utils/result.dart';

class PurchaseByPriceScreen extends StatefulWidget {
  const PurchaseByPriceScreen({super.key});

  @override
  State<PurchaseByPriceScreen> createState() => _PurchaseByPriceScreenState();
}

class _PurchaseByPriceScreenState extends State<PurchaseByPriceScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  List<Map<String, dynamic>> _summaryList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  Future<void> _fetchSummaryData() async {
    setState(() => _isLoading = true);
    final result = await _purchaseService.getPurchaseCountByPrice();

    if (mounted) {
      setState(() {
        _isLoading = false;
        switch (result) {
          case Ok(:final value):
            _summaryList = value;
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          '📊 สรุปการรับซื้อตามราคา',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 30, 40, 55),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSummaryData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _summaryList.isEmpty
                ? const Center(child: Text('ไม่พบข้อมูลการรับซื้อ'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _summaryList.length,
                    itemBuilder: (context, index) {
                      final item = _summaryList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.attach_money,
                                  color: Colors.green.shade700,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ราคา ${item['price']} บาท/กก.',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'น้ำหนักรวม: ${item['total_weight']} กก.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${item['total_count']}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    Text(
                                      'รายการ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
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
    );
  }
}