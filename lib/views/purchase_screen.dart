import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import '../models/purchase_model.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../utils/result.dart';

class PurchaseScreen extends StatefulWidget {
  final double todayPrice;
  final String priceId;

  const PurchaseScreen({
    super.key,
    required this.todayPrice,
    required this.priceId,
  });

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  String? _selectedVehiclePlate;
  String _selectedFarmerId = '';
  String _selectedFarmerName = '';

  // รายการรถที่จะดึงจาก Database
  List<Map<String, dynamic>> _vehicleList = [];
  bool _isLoadingVehicles = true;

  final _weightInController = TextEditingController();
  final _weightOutController = TextEditingController();
  final _drcController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVehicleList();

    _weightInController.addListener(_onInputChanged);
    _weightOutController.addListener(_onInputChanged);
    _drcController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _weightInController.dispose();
    _weightOutController.dispose();
    _drcController.dispose();
    super.dispose();
  }

  // 📌 ฟังก์ชันดึงรายการรถจาก DB ผ่าน Service
  Future<void> _fetchVehicleList() async {
    final service = context.read<PurchaseService>();
    final result = await service.getVehicles();

    if (mounted) {
      setState(() {
        if (result is Ok<List<Map<String, dynamic>>>) {
          _vehicleList = result.value;
        }
        _isLoadingVehicles = false;
      });
    }
  }

  void _onInputChanged() {
    final weightIn = double.tryParse(_weightInController.text) ?? 0;
    final weightOut = double.tryParse(_weightOutController.text) ?? 0;
    final drc = double.tryParse(_drcController.text) ?? 0;

    context.read<PurchaseViewModel>().calculate(
          weightIn: weightIn,
          weightOut: weightOut,
          drc: drc,
          buyPrice: widget.todayPrice,
        );
  }

  // 🎨 Helper ตกแต่ง Input Field ให้ตรงตามธีม
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF0F766E)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PurchaseViewModel>();

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
          'บันทึกการรับซื้อน้ำยางพารา',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. กล่องราคารับซื้อประจำวัน
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCCFBF1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.sell_outlined,
                          color: Color(0xFF0F766E),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ราคารับซื้อประจำวัน',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.todayPrice.toStringAsFixed(2)} บาท/กก.',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 📌 Card ฟอร์มกรอกข้อมูล
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลการรับซื้อ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Dropdown เลือกทะเบียนรถ (แก้ไขตรงจุดที่ขึ้นแดงแล้ว)
                  _isLoadingVehicles
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedVehiclePlate,
                          decoration: _buildInputDecoration(
                            labelText: 'เลือกทะเบียนรถ',
                            prefixIcon: Icons.directions_car_filled_outlined,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: _vehicleList.map((v) {
                            final plate = (v['car_number'] ?? '').toString();
                            final province = (v['province'] ?? '').toString();
                            final farmerName = (v['farmer_name'] ?? '').toString();

                            final displayLabel = '$plate ${province.isNotEmpty ? "($province)" : ""} ${farmerName.isNotEmpty ? "- $farmerName" : ""}';

                            return DropdownMenuItem<String>(
                              value: plate,
                              child: Text(
                                displayLabel,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedVehiclePlate = val;

                              final vehicle = _vehicleList.firstWhere(
                                (item) => (item['car_number'] ?? '').toString() == val,
                                orElse: () => {},
                              );

                              _selectedFarmerId = (vehicle['farmer_id'] ?? '').toString();
                              _selectedFarmerName = (vehicle['farmer_name'] ?? '').toString();
                            });
                          },
                        ),

                  // แสดงชื่อเจ้าของรถเมื่อเลือก
                  if (_selectedFarmerId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF15803D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'เจ้าของ : $_selectedFarmerName (ID : $_selectedFarmerId)',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 3. ช่องกรอก น้ำหนักเข้า - ออก
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightInController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _buildInputDecoration(
                            labelText: 'น้ำหนักเข้า',
                            prefixIcon: Icons.scale_outlined,
                            suffixText: 'กก.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightOutController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _buildInputDecoration(
                            labelText: 'น้ำหนักออก',
                            prefixIcon: Icons.scale_outlined,
                            suffixText: 'กก.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. เปอร์เซ็นต์ DRC
                  TextField(
                    controller: _drcController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _buildInputDecoration(
                      labelText: 'เปอร์เซ็นต์ยางแห้ง (% DRC)',
                      prefixIcon: Icons.percent_rounded,
                      suffixText: '%',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. กล่องแสดงผลคำนวณเงิน Real-time
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'น้ำหนักยางสดสุทธิ',
                        style: TextStyle(fontSize: 14.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${viewModel.calculatedRubberWeight.toStringAsFixed(2)} กก.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'น้ำหนักยางแห้งจริง',
                        style: TextStyle(fontSize: 14.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${viewModel.calculatedNetWeight.toStringAsFixed(2)} กก.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFDCFCE7)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'รวมเป็นเงินทั้งสิ้น',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${viewModel.calculatedTotalPrice.toStringAsFixed(2)} บาท',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. ปุ่มบันทึกรายการ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: viewModel.savePurchaseCommand.running
                    ? null
                    : () async {
                        final weightIn = double.tryParse(_weightInController.text) ?? 0;
                        final weightOut = double.tryParse(_weightOutController.text) ?? 0;
                        final drc = double.tryParse(_drcController.text) ?? 0;

                        if (_selectedVehiclePlate == null || _selectedFarmerId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('กรุณาเลือกทะเบียนรถ/เกษตรกร'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        if (weightIn <= 0 || weightIn <= weightOut || drc <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('กรุณากรอกน้ำหนักและ % DRC ให้ถูกต้อง'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        final rubberWeight = weightIn - weightOut;
                        final netWeight = rubberWeight * (drc / 100);
                        final totalPrice = netWeight * widget.todayPrice;

                        final record = PurchaseRecord(
                          farmerId: _selectedFarmerId,
                          weightIn: weightIn,
                          weightOut: weightOut,
                          rubberWeight: rubberWeight,
                          drc: drc,
                          netWeight: netWeight,
                          priceId: widget.priceId,
                          totalPrice: totalPrice,
                        );

                        await viewModel.savePurchaseCommand.execute(record);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('บันทึกการรับซื้อสำเร็จแล้ว!'),
                              backgroundColor: Color(0xFF0D9488),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: viewModel.savePurchaseCommand.running
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'บันทึกรายการ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}