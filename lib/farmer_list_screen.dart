import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'car_list_dialog.dart';
import 'register_car_dialog.dart';

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({Key? key}) : super(key: key);

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  // 🌐 URL Backend หลัก
  static const String baseUrl = "http://127.0.0.1:3000";

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> _farmersList = [];

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔄 ดึงข้อมูลเกษตรกรจาก API
  Future<void> _fetchFarmers() async {
    setState(() => _isLoading = true);
    final url = Uri.parse("$baseUrl/api/farmer/list");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['isError'] == false && resData['data'] is List) {
          if (!mounted) return;
          setState(() {
            _farmersList = List<Map<String, dynamic>>.from(
              (resData['data'] as List).map((item) => Map<String, dynamic>.from(item)),
            );
          });
        }
      } else {
        if (mounted) {
          _showSnackBar('โหลดข้อมูลไม่สำเร็จ (Status: ${response.statusCode})', Colors.orange);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('เกิดข้อผิดพลาดในการดึงข้อมูล: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✏ แก้ไขข้อมูลเกษตรกร
  Future<void> _updateFarmer(String farmerId, Map<String, dynamic> updateData) async {
    final url = Uri.parse("$baseUrl/api/farmers/$farmerId");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        if (mounted) _showSnackBar('แก้ไขข้อมูลสำเร็จ', const Color(0xFF0D9488));
        _fetchFarmers();
      } else {
        if (mounted) _showSnackBar('แก้ไขไม่สำเร็จ (Status: ${response.statusCode})', Colors.redAccent);
      }
    } catch (e) {
      if (mounted) _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.redAccent);
    }
  }

  // 🗑️ ลบข้อมูลเกษตรกร
  Future<void> _deleteFarmer(String farmerId) async {
    final url = Uri.parse("$baseUrl/api/farmers/$farmerId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (mounted) _showSnackBar('ลบข้อมูลเรียบร้อยแล้ว', const Color(0xFF0D9488));
        _fetchFarmers();
      } else {
        if (mounted) _showSnackBar('ลบไม่สำเร็จ (Status: ${response.statusCode})', Colors.redAccent);
      }
    } catch (e) {
      if (mounted) _showSnackBar('เกิดข้อผิดพลาดในการลบ: $e', Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditFarmerDialog(Map<String, dynamic> farmer) async {
    final farmerId = _getVal(farmer, ['farmer_id', 'Farmer_id', 'id']);

    final updatedData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditFarmerDialog(farmer: farmer, farmerId: farmerId),
    );

    if (updatedData != null && mounted) {
      _updateFarmer(farmerId, updatedData);
    }
  }

  void _confirmDeleteFarmer(Map<String, dynamic> farmer) {
    final farmerId = _getVal(farmer, ['farmer_id', 'Farmer_id', 'id']);
    final farmerName = _getVal(farmer, ['farmer_name', 'Farmer_name', 'name']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ยืนยันการลบข้อมูล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text('คุณต้องการลบข้อมูลเกษตรกร "$farmerName" (ID : $farmerId) ใช่หรือไม่ ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFarmer(farmerId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ลบข้อมูล'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredFarmers {
    if (_searchQuery.isEmpty) return _farmersList;
    return _farmersList.where((farmer) {
      final name = _getVal(farmer, ['farmer_name', 'Farmer_name', 'name']).toLowerCase();
      final id = _getVal(farmer, ['farmer_id', 'Farmer_id', 'id']).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  static String _getVal(Map<String, dynamic> map, List<String> keys, {String defaultValue = '-'}) {
    for (var key in keys) {
      if (map.containsKey(key) && map[key] != null && map[key].toString().trim().isNotEmpty) {
        return map[key].toString().trim();
      }
    }
    return defaultValue;
  }

  String _getFormattedAddress(Map<String, dynamic> farmer) {
    final address = _getVal(farmer, ['address', 'Address'], defaultValue: '');
    if (address.isNotEmpty && address != '-') return address;

    final subdistrict = _getVal(farmer, ['subdistrict', 'Subdistrict', 'tambon'], defaultValue: '');
    final district = _getVal(farmer, ['district', 'District', 'amphoe'], defaultValue: '');
    final province = _getVal(farmer, ['province', 'Province'], defaultValue: '');

    List<String> parts = [];
    if (subdistrict.isNotEmpty) parts.add("ต.$subdistrict");
    if (district.isNotEmpty) parts.add("อ.$district");
    if (province.isNotEmpty) parts.add("จ.$province");

    return parts.isNotEmpty ? parts.join(' ') : 'ไม่ระบุที่อยู่';
  }

  void _openCarOptions(Map<String, dynamic> farmer) {
    final farmerId = _getVal(farmer, ['farmer_id', 'Farmer_id', 'id']);
    final farmerName = _getVal(farmer, ['farmer_name', 'Farmer_name', 'name']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "จัดการรถ : $farmerName",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.directions_car_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('ดูรายการรถทั้งหมด', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => CarListDialog(
                        farmerId: farmerId,
                        farmerName: farmerName,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD1FAE5),
                    child: Icon(Icons.add_rounded, color: Color(0xFF059669)),
                  ),
                  title: const Text('ลงทะเบียนรถคันใหม่', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    await showDialog(
                      context: context,
                      builder: (context) => RegisterCarDialog(
                        farmerId: farmerId,
                        farmerName: farmerName,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredFarmers;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2837),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'รายชื่อเกษตรกร',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${list.length} ราย',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔍 ช่องค้นหา
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: "ค้นหาด้วยชื่อหรือรหัสเกษตรกร",
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📜 แสดงรายการข้อมูลเกษตรกร
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
                  )
                : list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            "ไม่พบข้อมูลเกษตรกร",
                            style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 2 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 280,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          return _buildFarmerCard(list[index]);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  // 💳 การ์ดข้อมูลเกษตรกร
  Widget _buildFarmerCard(Map<String, dynamic> farmer) {
    final farmerId = _getVal(farmer, ['farmer_id', 'Farmer_id', 'id']);
    final farmerName = _getVal(farmer, ['farmer_name', 'Farmer_name', 'name']);
    final phone = _getVal(farmer, ['phone', 'Phone']);
    final bankNum = _getVal(farmer, ['bank_number', 'Bank_number', 'bank_num']);
    final bankType = _getVal(farmer, ['bank_type', 'Bank_type', 'bank_name']);
    final formattedAddress = _getFormattedAddress(farmer);

    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    farmerName.isNotEmpty && farmerName != '-' ? farmerName[0] : 'ก',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_android, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 🏷️ ป้าย ID สไตล์ Soft Teal (ละมุน เข้ากับโทนสีหลักของแอป ไม่แย่งสายตา)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1), // เขียวมิ้นต์พาสเทล
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF99F6E4)), // เส้นขอบนุ่มๆ
                ),
                child: Text(
                  "ID : $farmerId",
                  style: const TextStyle(
                    color: Color(0xFF0F766E), // ตัวอักษรเขียวเข้มอ่านชัดเจน
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // 📌 ส่วนกล่องข้อมูลที่อยู่และธนาคาร
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ที่อยู่
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 19, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ที่อยู่ : $formattedAddress",
                        style: const TextStyle(
                          fontSize: 15.5,
                          color: Color(0xFF334155),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 2. ธนาคาร
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 19, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ธนาคาร : $bankType",
                        style: const TextStyle(
                          fontSize: 15.5,
                          color: Color(0xFF334155),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 3. เลขบัญชี
                Row(
                  children: [
                    const Icon(Icons.credit_card_outlined, size: 19, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "เลขบัญชี : $bankNum",
                        style: const TextStyle(
                          fontSize: 15.5,
                          color: Color(0xFF334155),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCarOptions(farmer),
                    icon: const Icon(Icons.directions_car_filled, size: 20),
                    label: const Text(
                      "จัดการรถ",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showEditFarmerDialog(farmer),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 22, color: Color(0xFFD97706)),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _confirmDeleteFarmer(farmer),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, size: 22, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 📌 Dialog แก้ไขข้อมูลเกษตรกร (ปรับดีไซน์ให้แมตช์ธีมหลัก)
class EditFarmerDialog extends StatefulWidget {
  final Map<String, dynamic> farmer;
  final String farmerId;

  const EditFarmerDialog({
    Key? key,
    required this.farmer,
    required this.farmerId,
  }) : super(key: key);

  @override
  State<EditFarmerDialog> createState() => _EditFarmerDialogState();
}

class _EditFarmerDialogState extends State<EditFarmerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _bankNumCtrl;

  late List<String> _bankOptions;
  late String _selectedBank;

  @override
  void initState() {
    super.initState();
    final f = widget.farmer;

    _nameCtrl = TextEditingController(text: _getVal(f, ['farmer_name', 'Farmer_name', 'name']));
    _phoneCtrl = TextEditingController(text: _getVal(f, ['phone', 'Phone']));

    String existingAddress = _getVal(f, ['address', 'Address']);
    if (existingAddress.isEmpty) {
      List<String> parts = [];
      final houseNo = _getVal(f, ['house_no', 'houseNo']);
      final subdistrict = _getVal(f, ['subdistrict', 'Subdistrict', 'tambon']);
      final district = _getVal(f, ['district', 'District', 'amphoe']);
      final province = _getVal(f, ['province', 'Province']);

      if (houseNo.isNotEmpty) parts.add(houseNo);
      if (subdistrict.isNotEmpty) parts.add("ต.$subdistrict");
      if (district.isNotEmpty) parts.add("อ.$district");
      if (province.isNotEmpty) parts.add("จ.$province");

      existingAddress = parts.join(' ');
    }

    _addressCtrl = TextEditingController(text: existingAddress);
    _bankNumCtrl = TextEditingController(text: _getVal(f, ['bank_number', 'Bank_number', 'bank_num']));

    _bankOptions = ['กรุงไทย',  'กสิกรไทย', 'ไทยพาณิชย์', 'กรุงเทพ'];
    final currentBank = _getVal(f, ['bank_type', 'Bank_type', 'bank_name']);

    if (currentBank.isNotEmpty && !_bankOptions.contains(currentBank)) {
      _bankOptions.add(currentBank);
    }
    _selectedBank = currentBank.isNotEmpty ? currentBank : 'กรุงไทย';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bankNumCtrl.dispose();
    super.dispose();
  }

  String _getVal(Map<String, dynamic> map, List<String> keys) {
    for (var key in keys) {
      if (map.containsKey(key) && map[key] != null && map[key].toString() != '-') {
        return map[key].toString().trim();
      }
    }
    return '';
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0F766E)),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 Header Bar พร้อม Badge แสดงรหัสเกษตรกร
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF0F766E),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'แก้ไขข้อมูลเกษตรกร',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF99F6E4)),
                          ),
                          child: Text(
                            'ID : ${widget.farmerId}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 20),

              // 1. ชื่อ-นามสกุล
              TextField(
                controller: _nameCtrl,
                decoration: _buildInputDecoration('ชื่อ - นามสกุล', Icons.person_outline),
              ),
              const SizedBox(height: 16),

              // 2. เบอร์โทรศัพท์
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration('เบอร์โทรศัพท์', Icons.phone_android),
              ),
              const SizedBox(height: 16),

              // 3. ที่อยู่
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: _buildInputDecoration('ที่อยู่', Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),

              // 4. ธนาคาร
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: _buildInputDecoration('ธนาคาร', Icons.account_balance_outlined),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                items: _bankOptions.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBank = val);
                },
              ),
              const SizedBox(height: 16),

              // 5. เลขบัญชีธนาคาร
              TextField(
                controller: _bankNumCtrl,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('เลขบัญชีธนาคาร', Icons.credit_card),
              ),

              const SizedBox(height: 28),

              // 📌 ปุ่มจัดการ (ยกเลิก / บันทึกการเปลี่ยนแปลง)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final updateData = {
                          "farmer_name": _nameCtrl.text.trim(),
                          "phone": _phoneCtrl.text.trim(),
                          "address": _addressCtrl.text.trim(),
                          "bank_type": _selectedBank,
                          "bank_number": _bankNumCtrl.text.trim(),
                        };
                        Navigator.pop(context, updateData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'บันทึกการเปลี่ยนแปลง',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}