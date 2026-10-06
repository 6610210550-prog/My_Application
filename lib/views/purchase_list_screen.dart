import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
import '../utils/result.dart';
import 'purchase_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final PurchaseService _purchaseService = PurchaseService();

  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = false;

  // 📌 รายการราคารับซื้อสำหรับ Dropdown
  List<Map<String, dynamic>> _priceAnalyticsList = [];
  Map<String, dynamic>? _selectedAnalyticsPrice;
  bool _isLoadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
    _fetchPriceAnalytics();
  }

  // 1. ดึงรายการรับซื้อทั้งหมด
  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);
    final result = await _purchaseService.getAllPurchases();
    if (mounted) {
      setState(() {
        _isLoading = false;
        switch (result) {
          case Ok(:final value):
            _purchases = value;
          case Error(:final error):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาด: ${error.toString()}')),
            );
        }
      });
    }
  }

  // 2. ดึงสถิติตามราคาใส่ Dropdown
  Future<void> _fetchPriceAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    final result = await _purchaseService.getPurchaseCountByPrice();
    if (mounted) {
      setState(() {
        _isLoadingAnalytics = false;
        if (result is Ok<List<Map<String, dynamic>>>) {
          _priceAnalyticsList = result.value;
        }
      });
    }
  }

  // 3. ฟังก์ชันกรองรายการรับซื้อตามราคาที่เลือก
  // 📌 ฟังก์ชันกรองรายการรับซื้อโดยเช็กจาก buy_price โดยตรง
List<Map<String, dynamic>> get _filteredPurchases {
  // ถ้าไม่ได้เลือก หรือเลือก "ทั้งหมด" ให้คืนค่ารายการทั้งหมด
  if (_selectedAnalyticsPrice == null || _selectedAnalyticsPrice!['price_id'] == 'ALL') {
    return _purchases;
  }

  // แปลงราคาที่เลือกจาก Dropdown เป็น double
  final double selectedPrice = double.tryParse(_selectedAnalyticsPrice!['price_value']?.toString() ?? '') ?? 0.0;

  return _purchases.where((item) {
    // 1. เช็กราคาจากคอลัมน์ buy_price หรือ price_value ที่แนบมากับรายการรับซื้อ
    final rawPrice = item['buy_price'] ?? item['price_value'] ?? item['price'];
    
    if (rawPrice != null) {
      final double itemPrice = double.tryParse(rawPrice.toString()) ?? -1.0;
      if ((itemPrice - selectedPrice).abs() < 0.01) { // เทียบ double ป้องกันปัญหาทศนิยม
        return true;
      }
    }

    // 2. สำรอง: ถ้า API ไม่ได้ JOIN ตาราง price มา ให้คำนวณราคาต่อ กก. จาก (ราคารวม / น้ำหนัก)
    final double weight = double.tryParse(item['rubber_weight']?.toString() ?? '') ?? 0.0;
    final double totalPrice = double.tryParse(item['total_price']?.toString() ?? '') ?? 0.0;
    
    if (weight > 0 && totalPrice > 0) {
      final double calculatedPrice = totalPrice / weight;
      if ((calculatedPrice - selectedPrice).abs() < 0.5) { // ยอมรับความคลาดเคลื่อนเล็กน้อยจาก DRC
        return true;
      }
    }

    // 3. สำรอง: เทียบด้วย price_id (กรณีตรงกัน)
    if (item['price_id'] != null && item['price_id'].toString() == _selectedAnalyticsPrice!['price_id'].toString()) {
      return true;
    }

    return false;
  }).toList();
}

  // 4. Dialog แก้ไข Purchase
  void _showEditDialog(Map<String, dynamic> item) {
    final weightController = TextEditingController(text: item['rubber_weight']?.toString() ?? '0');
    final drcController = TextEditingController(text: item['drc']?.toString() ?? '0');
    final totalPriceController = TextEditingController(text: item['total_price']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไขรายการ ${item['purchase_id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'น้ำหนักยาง (กก.)'),
            ),
            TextField(
              controller: drcController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DRC (%)'),
            ),
            TextField(
              controller: totalPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ราคารวม (บาท)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedData = {
                'farmer_id': item['farmer_id'],
                'weight_in': item['weight_in'],
                'weight_out': item['weight_out'],
                'rubber_weight': double.tryParse(weightController.text) ?? 0,
                'drc': double.tryParse(drcController.text) ?? 0,
                'net_weight': item['net_weight'],
                'total_price': double.tryParse(totalPriceController.text) ?? 0,
                'rubber_type': item['rubber_type'] ?? 'สด',
              };

              final result = await _purchaseService.updatePurchase(item['purchase_id'], updatedData);
              if (context.mounted) {
                Navigator.pop(context);
                _fetchPurchases();
                _fetchPriceAnalytics();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result is Ok ? 'แก้ไขข้อมูลสำเร็จ' : 'เกิดข้อผิดพลาดในการแก้ไข'),
                    backgroundColor: result is Ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // 5. Confirm Dialog สำหรับการลบ
  void _confirmDelete(String purchaseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบรายการรับซื้อ "$purchaseId" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final res = await _purchaseService.deletePurchase(purchaseId);
              if (context.mounted) {
                Navigator.pop(context);
                _fetchPurchases();
                _fetchPriceAnalytics();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res is Ok ? 'ลบรายการสำเร็จ' : 'ลบไม่สำเร็จ')),
                );
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredPurchases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการรับซื้อน้ำยาง'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          final priceResult = await _purchaseService.getPurchaseCountByPrice();

          if (mounted) Navigator.pop(context);

          double todayPrice = 50.0;
          String priceId = 'PR00000001';

          if (priceResult is Ok<List<Map<String, dynamic>>> && priceResult.value.isNotEmpty) {
            final latestPrice = priceResult.value.first;
            todayPrice = double.tryParse(latestPrice['price_value']?.toString() ?? '') ?? 50.0;
            priceId = latestPrice['price_id']?.toString() ?? 'PR00000001';
          }

          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PurchaseScreen(
                  todayPrice: todayPrice,
                  priceId: priceId,
                ),
              ),
            );

            _fetchPurchases();
            _fetchPriceAnalytics();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการรับซื้อ'),
      ),
      body: Column(
        children: [
          // 🔽 Dropdown เลือกราคารับซื้อเพื่อกรองรายการ
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔍 กรองรายการรับซื้อตามราคา',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingAnalytics
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedAnalyticsPrice,
                            decoration: const InputDecoration(
                              labelText: 'เลือกราคารับซื้อ (บาท/กก.)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.sell, color: Colors.green),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              // เพิ่มตัวเลือก "แสดงทั้งหมด"
                              const DropdownMenuItem<Map<String, dynamic>>(
                                value: {'price_id': 'ALL', 'price_value': 'ทั้งหมด'},
                                child: Text('ทั้งหมด'),
                              ),
                              ..._priceAnalyticsList.map((item) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: item,
                                  child: Text('${item['price_value']} บาท/กก.'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedAnalyticsPrice = val;
                              });
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการรับซื้อ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Text(
                  'พบ ${displayList.length} รายการ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 📋 รายการที่ถูกกรองตามราคาที่เลือก
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? const Center(child: Text('ไม่พบรายการรับซื้อตามราคาที่เลือก'))
                    : ListView.builder(
                        itemCount: displayList.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final item = displayList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(
                                '👨‍🌾 ${item['farmer_name'] ?? '-'} (${item['purchase_id']})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'น้ำหนัก: ${item['rubber_weight']} กก. | DRC: ${item['drc']}% | รวม: ${item['total_price']} บาท\nวันที่: ${item['purchase_date']}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditDialog(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () => _confirmDelete(item['purchase_id']),
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
    );
  }
}