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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PurchaseViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกการรับซื้อน้ำยางพารา')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. กล่องราคารับซื้อประจำวัน
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ราคารับซื้อประจำวัน:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${widget.todayPrice} บาท/กก.',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],  
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Dropdown ทะเบียนรถ (ดึงสดจาก DB)
              // 2. Dropdown ทะเบียนรถ (ดึงสดจาก DB)
_isLoadingVehicles
    ? const Center(child: CircularProgressIndicator())
    : DropdownButtonFormField<String>(
        initialValue: _selectedVehiclePlate,
        decoration: const InputDecoration(
          labelText: 'เลือกทะเบียนรถ',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.directions_car),
        ),
        items: _vehicleList.map((v) {
          final plate = (v['car_number'] ?? '').toString();
          final province = (v['province'] ?? '').toString();
          final farmerName = (v['farmer_name'] ?? '').toString();

          final displayLabel = '$plate ${province.isNotEmpty ? "($province)" : ""} ${farmerName.isNotEmpty ? "($farmerName)" : ""}';

          return DropdownMenuItem<String>(
            value: plate,
            child: Text(displayLabel),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedVehiclePlate = val;

            // 📌 ค้นหารถในรายการโดยเทียบกับ 'car_number'
            final vehicle = _vehicleList.firstWhere(
              (item) => (item['car_number'] ?? '').toString() == val,
              orElse: () => {},
            );

            // 📌 ดึง farmer_id และ farmer_name ให้ตรงกับชื่อคอลัมน์จาก DB
            _selectedFarmerId = (vehicle['farmer_id'] ?? '').toString();
            _selectedFarmerName = (vehicle['farmer_name'] ?? '').toString();
          });
        },
      ),

              if (_selectedFarmerId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'เจ้าของ: $_selectedFarmerName (รหัส: $_selectedFarmerId)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'น้ำหนักเข้า (กก.)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _onInputChanged(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightOutController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'น้ำหนักออก (กก.)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _onInputChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. เปอร์เซ็นต์ DRC
              TextField(
                controller: _drcController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'เปอร์เซ็นต์ยางแห้ง (% DRC)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _onInputChanged(),
              ),
              const SizedBox(height: 20),

              // 5. กล่องแสดงผลคำนวณเงิน Real-time
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('น้ำหนักยางสดสุทธิ:'),
                        Text(
                          '${viewModel.calculatedRubberWeight.toStringAsFixed(2)} กก.',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('น้ำหนักยางแห้งจริง:'),
                        Text(
                          '${viewModel.calculatedNetWeight.toStringAsFixed(2)} กก.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'รวมเป็นเงินทั้งสิ้น:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${viewModel.calculatedTotalPrice.toStringAsFixed(2)} บาท',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
  onPressed: viewModel.savePurchaseCommand.running
      ? null
      : () async {
          final weightIn = double.tryParse(_weightInController.text) ?? 0;
          final weightOut = double.tryParse(_weightOutController.text) ?? 0;
          final drc = double.tryParse(_drcController.text) ?? 0;

          if (_selectedVehiclePlate == null || _selectedFarmerId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กรุณาเลือกทะเบียนรถ/เกษตรกร')),
            );
            return;
          }

          if (weightIn <= 0 || weightIn <= weightOut || drc <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กรุณากรอกน้ำหนักและ % DRC ให้ถูกต้อง')),
            );
            return;
          }

          // 📌 คำนวณค่าสดตรงนี้ก่อนส่ง
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
            totalPrice: totalPrice, // 👈 ส่งค่าที่คำนวณแล้วแบบชัวร์ๆ
          );

          await viewModel.savePurchaseCommand.execute(record);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('บันทึกการรับซื้อสำเร็จแล้ว!')),
            );
            Navigator.pop(context);
          }
        },
  child: const Text('บันทึกรายการ'),
)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
