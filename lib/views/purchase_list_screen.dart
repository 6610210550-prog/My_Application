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
  String _selectedPriceId = 'ALL';
  bool _isLoadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
    _fetchPriceAnalytics();
  }

  // 1. ดึงรายการรับซื้อทั้งหมด (แปลง Type อย่างปลอดภัยสำหรับ Flutter Web)
  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);
    final result = await _purchaseService.getAllPurchases();
    if (mounted) {
      setState(() {
        _isLoading = false;
        switch (result) {
          case Ok(:final value):
            try {
              if (value is List) {
                _purchases = value
                    .where((e) => e != null)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();
              } else {
                _purchases = [];
              }
            } catch (_) {
              _purchases = [];
            }
          case Error(:final error):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: ${error.toString()}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      });
    }
  }

  // 2. ดึงสถิติตามราคาใส่ Dropdown (แปลง Type อย่างปลอดภัย)
  Future<void> _fetchPriceAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    final result = await _purchaseService.getPurchaseCountByPrice();
    if (mounted) {
      setState(() {
        _isLoadingAnalytics = false;
        if (result is Ok) {
          final rawValue = (result as Ok).value;
          if (rawValue is List) {
            _priceAnalyticsList = rawValue
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        }
      });
    }
  }

  // 3. ฟังก์ชันกรองรายการรับซื้อ
  List<Map<String, dynamic>> get _filteredPurchases {
    if (_selectedPriceId == 'ALL') {
      return _purchases;
    }

    final selectedItem = _priceAnalyticsList.firstWhere(
      (item) => item['price_id']?.toString() == _selectedPriceId,
      orElse: () => {},
    );

    if (selectedItem.isEmpty) return _purchases;

    final double selectedPrice = double.tryParse(selectedItem['price_value']?.toString() ?? '') ?? 0.0;

    return _purchases.where((item) {
      final rawPrice = item['buy_price'] ?? item['price_value'] ?? item['price'];
      if (rawPrice != null) {
        final double itemPrice = double.tryParse(rawPrice.toString()) ?? -1.0;
        if ((itemPrice - selectedPrice).abs() < 0.01) {
          return true;
        }
      }

      final double weight = double.tryParse(item['rubber_weight']?.toString() ?? '') ?? 0.0;
      final double totalPrice = double.tryParse(item['total_price']?.toString() ?? '') ?? 0.0;
      if (weight > 0 && totalPrice > 0) {
        final double calculatedPrice = totalPrice / weight;
        if ((calculatedPrice - selectedPrice).abs() < 0.5) {
          return true;
        }
      }

      if (item['price_id'] != null && item['price_id'].toString() == _selectedPriceId) {
        return true;
      }

      return false;
    }).toList();
  }

  // Helper ตกแต่ง Input Field
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13.5, fontWeight: FontWeight.w600),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF0F766E)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  // 4. Dialog แก้ไข Purchase
  void _showEditDialog(Map<String, dynamic> item) {
    final weightController = TextEditingController(text: item['rubber_weight']?.toString() ?? '0');
    final drcController = TextEditingController(text: item['drc']?.toString() ?? '0');
    final totalPriceController = TextEditingController(text: item['total_price']?.toString() ?? '0');
    final purchaseId = item['purchase_id']?.toString() ?? '-';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F766E), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'แก้ไขรายการรับซื้อ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ID : $purchaseId',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15),
                decoration: _buildInputDecoration(labelText: 'น้ำหนักยาง (กก.)', prefixIcon: Icons.scale_outlined),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: drcController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15),
                decoration: _buildInputDecoration(labelText: 'DRC (%)', prefixIcon: Icons.percent_rounded),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: totalPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15),
                decoration: _buildInputDecoration(labelText: 'ราคารวม (บาท)', prefixIcon: Icons.payments_outlined),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF0F766E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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

                    final result = await _purchaseService.updatePurchase(purchaseId, updatedData);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _fetchPurchases();
                      _fetchPriceAnalytics();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result is Ok ? 'แก้ไขข้อมูลสำเร็จ' : 'เกิดข้อผิดพลาดในการแก้ไข'),
                          backgroundColor: result is Ok ? const Color(0xFF0D9488) : Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('บันทึก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('ยืนยันการลบรายการ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
          ],
        ),
        content: Text(
          'คุณต้องการลบรายการรับซื้อ "$purchaseId" ใช่หรือไม่? ข้อมูลนี้จะถูกลบออกจากระบบอย่างถาวร',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.4),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final res = await _purchaseService.deletePurchase(purchaseId);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _fetchPurchases();
                      _fetchPriceAnalytics();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res is Ok ? 'ลบรายการสำเร็จ' : 'ลบไม่สำเร็จ'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('ลบข้อมูล', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredPurchases;

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
          'รายการรับซื้อน้ำยาง',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            ),
          );

          final priceResult = await _purchaseService.getPurchaseCountByPrice();

          if (mounted) Navigator.pop(context);

          double todayPrice = 50.0;
          String priceId = 'PR00000001';

          if (priceResult is Ok && (priceResult as Ok).value is List) {
            final list = (priceResult as Ok).value as List;
            if (list.isNotEmpty && list.first != null) {
              final latestPrice = Map<String, dynamic>.from(list.first as Map);
              todayPrice = double.tryParse(latestPrice['price_value']?.toString() ?? '') ?? 50.0;
              priceId = latestPrice['price_id']?.toString() ?? 'PR00000001';
            }
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มรายการรับซื้อ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: Column(
        children: [
          // Dropdown เลือกราคารับซื้อเพื่อกรองรายการ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
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
                  Row(
                    children: const [
                      Icon(Icons.filter_alt_outlined, size: 20, color: Color(0xFF0F766E)),
                      SizedBox(width: 6),
                      Text(
                        'กรองรายการรับซื้อตามราคา',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoadingAnalytics
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedPriceId,
                          isExpanded: true,
                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
                          decoration: _buildInputDecoration(
                            labelText: 'เลือกราคารับซื้อ (บาท/กก.)',
                            prefixIcon: Icons.sell_outlined,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF334155)),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'ALL',
                              child: Text('แสดงรายการทั้งหมด', style: TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                            ),
                            ..._priceAnalyticsList
                                .where((item) => item['price_id'] != null)
                                .map((item) {
                              final String id = item['price_id'].toString();
                              final String priceVal = item['price_value']?.toString() ?? '0';
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text('$priceVal บาท/กก.', style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPriceId = val;
                              });
                            }
                          },
                        ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการรับซื้อ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'พบ ${displayList.length} รายการ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 📋 รายการ Card รับซื้อ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
                : displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inbox_outlined, size: 52, color: Color(0xFF64748B)),
                            SizedBox(height: 10),
                            Text(
                              'ไม่พบรายการรับซื้อตามราคาที่เลือก',
                              style: TextStyle(color: Color(0xFF334155), fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayList.length,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemBuilder: (context, index) {
                          final item = displayList[index];

                          final farmerName = item['farmer_name']?.toString() ?? '-';
                          final purchaseId = item['purchase_id']?.toString() ?? '';
                          final rubberWeight = item['rubber_weight']?.toString() ?? '0';
                          final drc = item['drc']?.toString() ?? '0';
                          final totalPrice = item['total_price']?.toString() ?? '0';
                          final purchaseDate = item['purchase_date']?.toString() ?? '-';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x06000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // รายละเอียดข้อมูล
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            farmerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (purchaseId.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFCCFBF1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'ID : $purchaseId',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F766E),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'น้ำหนัก : $rubberWeight กก.  |  DRC : $drc%',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF475569)),
                                          const SizedBox(width: 5),
                                          Text(
                                            'วันที่ : $purchaseDate',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF86EFAC)),
                                        ),
                                        child: Text(
                                          'รวม : $totalPrice บาท',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ปุ่มแก้ไข & ลบ
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF1D4ED8), size: 22),
                                      onPressed: () => _showEditDialog(item),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
                                      onPressed: () => _confirmDelete(purchaseId),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                  ],
                                ),
                              ],
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