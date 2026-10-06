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

  // ✏️️ แก้ไขข้อมูลเกษตรกรผ่าน API
  Future<void> _updateFarmer(String farmerId, Map<String, dynamic> updateData) async {
    final url = Uri.parse("$baseUrl/api/farmers/$farmerId");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showSnackBar('แก้ไขข้อมูลเกษตรกรสำเร็จ', Colors.green);
        }
        _fetchFarmers();
      } else {
        if (mounted) {
          _showSnackBar('แก้ไขไม่สำเร็จ (Status: ${response.statusCode})', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.red);
      }
    }
  }

  // 🗑️ ลบข้อมูลเกษตรกรผ่าน API
  Future<void> _deleteFarmer(String farmerId) async {
    final url = Uri.parse("$baseUrl/api/farmers/$farmerId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (mounted) {
          _showSnackBar('ลบข้อมูลเกษตรกรเรียบร้อยแล้ว', Colors.green);
        }
        _fetchFarmers(); // 🔄 โหลดข้อมูลใหม่ทันที
      } else {
        if (mounted) {
          _showSnackBar('ลบไม่สำเร็จ (Status: ${response.statusCode})', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('เกิดข้อผิดพลาดในการลบ: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
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

  // ⚠️ Pop-up ยืนยันก่อนลบ
  void _confirmDeleteFarmer(Map<String, dynamic> farmer) {
    final farmerId = _getVal(farmer, ['farmer_id', 'Farmer_id', 'id']);
    final farmerName = _getVal(farmer, ['farmer_name', 'Farmer_name', 'name']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
              SizedBox(width: 8),
              Text('ยืนยันการลบข้อมูล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('คุณต้องการลบข้อมูลเกษตรกร "$farmerName" (ID: $farmerId) ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFarmer(farmerId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "จัดการรถ: $farmerName",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: const Color(0xFFF1F5F9),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0x1A0284C7), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.directions_car_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text("ดูรายการรถ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("รายการยานพาหนะที่ลงทะเบียนไว้", style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
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
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: const Color(0xFFF1F5F9),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0x1A10B981), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
                  ),
                  title: const Text("ลงทะเบียนรถใหม่", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("เพิ่มรถคันใหม่เข้าสู่ระบบ", style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
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
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'รายชื่อเกษตรกร',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    "${list.length} ราย",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 ช่องค้นหา
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "ค้นหาด้วยชื่อ หรือรหัสเกษตรกร...",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 📜 รายการการ์ดเกษตรกร
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E293B)))
                : RefreshIndicator(
                    onRefresh: _fetchFarmers,
                    color: const Color(0xFF1E293B),
                    child: list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
                                    SizedBox(height: 12),
                                    Text(
                                      "ไม่พบข้อมูลเกษตรกรที่ค้นหา",
                                      style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: isDesktop
                                  ? GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisExtent: 250,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: list.length,
                                      itemBuilder: (context, index) => _buildFarmerCard(list[index]),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                      itemCount: list.length,
                                      itemBuilder: (context, index) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildFarmerCard(list[index]),
                                      ),
                                    ),
                            ),
                          ),
                  ),
          ),
        ],
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
            color: Color(0x0D0F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    farmerName.isNotEmpty && farmerName != '-' ? farmerName[0] : 'ก',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmerName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(phone, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "ID: $farmerId",
                    style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "ที่อยู่ : $formattedAddress",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.25),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.account_balance_outlined, size: 15, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ธนาคาร : $bankType",
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "เลขบัญชี : $bankNum",
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCarOptions(farmer),
                    icon: const Icon(Icons.directions_car_filled_rounded, size: 15),
                    label: const Text("จัดการรถ", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showEditFarmerDialog(farmer),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 17, color: Color(0xFFD97706)),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _confirmDeleteFarmer(farmer),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 📌 Mobile / Desktop Dialog แก้ไขข้อมูลเกษตรกร
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

    _bankOptions = ['กรุงไทย', 'ธ.ก.ส.', 'กสิกรไทย', 'ไทยพาณิชย์', 'กรุงเทพ'];
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('แก้ไขข้อมูลเกษตรกร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'ชื่อ - นามสกุล',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ที่อยู่',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: InputDecoration(
                  labelText: 'ธนาคาร',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _bankOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBank = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bankNumCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'เลขบัญชีธนาคาร',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
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
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}