import 'register_farmer_screen.dart';
import 'farmer_list_screen.dart';
import 'register_vehicle_screen.dart';
import 'latex_purchase_screen.dart';
import 'daily_price_screen.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // <-- เพิ่มการนำเข้า http
import 'dart:convert'; // <-- เพิ่มการนำเข้า json convert
import 'views/purchase_screen.dart';
import 'farmer_list_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = "";
  String _todayPrice = "-"; // <-- เพิ่มตัวแปรสำหรับเก็บราคาของวันนี้

  // สำหรับสไลด์ Banner อัตโนมัติ
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  final List<String> _bannerImages = ['assets/banner.png', 'assets/pr1.jpg'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTodayPrice(); // <-- เรียกดึงราคาของวันนี้
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString("username") ?? "ผู้ใช้งาน";
    });
  }

  // 📌 ฟังก์ชันดึงราคาของวันนี้จาก API Backend
  Future<void> _fetchTodayPrice() async {
    final url = Uri.parse("http://127.0.0.1:3000/api/price/get_today_price");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isError'] == false && data['data'] != null) {
          setState(() {
            _todayPrice = "฿${data['data']['buy_price']}";
          });
        } else {
          setState(() {
            _todayPrice = "ยังไม่กำหนด";
          });
        }
      } else {
        setState(() {
          _todayPrice = " error";
        });
      }
    } catch (e) {
      setState(() {
        _todayPrice = "-";
      });
    }
  }

  // ลูกเล่นสไลด์ Banner ทุกๆ 3 วินาที
  void _startBannerAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        int nextPage = (_currentBannerIndex + 1) % _bannerImages.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
        _startBannerAutoSlide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      // AppBar ด้านบนพร้อมปุ่ม 3 ขีด
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2538),
        elevation: 0,
        title: const Text(
          "หน้าหลัก",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // ปุ่ม 3 ขีดสีขาว
      ),

      // เมนูสไลด์ด้านข้าง พร้อมกำหนดค่า index = 0 สำหรับหน้าหลัก
      drawer: _buildAppDrawer(currentIndex: 0),

      // เนื้อหาหน้าหลัก (แสดงเต็มหน้าจอ)
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ข้อความต้อนรับ
                Text(
                  "ยินดีต้อนรับ, คุณ$_username 👋",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2538),
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Banner รูปภาพพร้อม Auto-Slide Carousel
                _buildInteractiveBanner(),

                const SizedBox(height: 20),

                // 2. แดชบอร์ด 4 กล่องเล็ก เรียงแนวนอน
                const Text(
                  "แดชบอร์ดสรุปผล",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2538),
                  ),
                ),
                const SizedBox(height: 12),
                _buildHorizontalDashboardGrid(),

                const SizedBox(height: 24),

                // 3. เมนูการใช้งานด้านล่าง
                const Text(
                  "เมนูการใช้งาน",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2538),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Widget: Drawer (เมนูที่จะสไลด์ออกมาเมื่อกดปุ่ม 3 ขีด)
  // -----------------------------------------------------------------
  Widget _buildAppDrawer({required int currentIndex}) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E2538),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF181D2D)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/tar.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.business,
                              size: 40,
                              color: Color(0xFF2E6D52),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "บริษัท พัทลุงพาราเท็กซ์ จำกัด",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildDrawerItem(
                    index: 0,
                    currentIndex: currentIndex,
                    emoji: "🏡",
                    label: "หน้าหลัก",
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    index: 1,
                    currentIndex: currentIndex,
                    emoji: "➕",
                    label: "ลงทะเบียนเกษตรกร",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterFarmerScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    index: 2,
                    currentIndex: currentIndex,
                    emoji: "📋",
                    label: "รายชื่อเกษตรกร",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmerListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    index: 3,
                    currentIndex: currentIndex,
                    emoji: "🚗",
                    label: "ลงทะเบียนรถ",
                    onTap: () {
                      Navigator.pop(context);

                      // ดึงเฉพาะตัวเลขราคารับซื้อออกจากสตริง (เช่น "฿55.0" -> 55.0)
                      final cleanPriceText = _todayPrice
                          .replaceAll('฿', '')
                          .trim();
                      final double parsedPrice =
                          double.tryParse(cleanPriceText) ?? 0.0;

                      // ดึงวันที่ปัจจุบันในรูปแบบ YYYY-MM-DD สำหรับ priceId
                      final String todayDateStr = DateTime.now()
                          .toIso8601String()
                          .split('T')[0];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterVehicleScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                   index: 4,
  currentIndex: currentIndex,
  emoji: "💧", 
  label: "บันทึกรับซื้อน้ำยาง", 
  onTap: () {
    Navigator.pop(context);

    // ดึงเฉพาะตัวเลขราคารับซื้อออกจากสตริง (เช่น "฿55.0" -> 55.0)
    final cleanPriceText = _todayPrice.replaceAll('฿', '').trim();
    final double parsedPrice = double.tryParse(cleanPriceText) ?? 0.0;
    
    // ดึงวันที่ปัจจุบันในรูปแบบ YYYY-MM-DD สำหรับ priceId
    final String todayDateStr = DateTime.now().toIso8601String().split('T')[0];

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => PurchaseScreen(
          todayPrice: parsedPrice,
          priceId: todayDateStr,
        ),
      ),
    );
  },
),
                  _buildDrawerItem(
                    index: 5,
                    currentIndex: currentIndex,
                    emoji: "💰",
                    label: "ตั้งราคาประจำวัน",
                    onTap: () async {
                      Navigator.pop(context);
                      // เมื่อกลับมาจากหน้าตั้งราคา ให้รีเฟรชราคาใหม่ด้วย
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyPriceScreen(),
                        ),
                      );
                      _fetchTodayPrice();
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            _buildLogoutDrawerItem(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required int currentIndex,
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    bool isSelected = index == currentIndex;

    return _DrawerHoverItem(
      isSelected: isSelected,
      onTap: onTap,
      emoji: emoji,
      label: label,
    );
  }

  Widget _buildLogoutDrawerItem() {
    return _LogoutHoverItem(
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) Navigator.pop(context);
      },
    );
  }

  // -----------------------------------------------------------------
  // Widget: Interactive Banner
  // -----------------------------------------------------------------
  Widget _buildInteractiveBanner() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (index) {
                setState(() => _currentBannerIndex = index);
              },
              itemCount: _bannerImages.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _bannerImages[index],
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2E6D52),
                      child: Center(
                        child: Text(
                          _bannerImages[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentBannerIndex == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? const Color(0xFF2E6D52)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // Widget: แดชบอร์ด 4 กล่องเล็ก
  // -----------------------------------------------------------------
  Widget _buildHorizontalDashboardGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _buildSmallStatCard(
          title: "เกษตรกรทั้งหมด",
          value: "6 ราย",
          icon: Icons.groups_rounded,
          iconBgColor: const Color(0xFFE8EEFF),
          iconColor: const Color(0xFF4C6FFF),
          valueColor: const Color(0xFF2563EB),
        ),
        _buildSmallStatCard(
          title: "น้ำหนักรวมวันนี้",
          value: "0 กก.",
          icon: Icons.scale_rounded,
          iconBgColor: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          valueColor: const Color(0xFF059669),
        ),
        _buildSmallStatCard(
          title: "ยอดชำระรวม",
          value: "฿159,690",
          icon: Icons.account_balance_wallet_rounded,
          iconBgColor: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          valueColor: const Color(0xFFD97706),
        ),
        _buildSmallStatCard(
          title: "ราคารับซื้อวันนี้",
          value: _todayPrice, // <-- ใช้ค่า dynamic จากตัวแปร _todayPrice
          icon: Icons.calendar_month_rounded,
          iconBgColor: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
          valueColor: const Color(0xFF4C1D95),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color valueColor,
  }) {
    return _HoverAnimatedCard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Widget: เมนูลัดด้านล่าง
  // -----------------------------------------------------------------
  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _buildMenuCard(
          title: "ลงทะเบียนเกษตรกร",
          emoji: "➕",
          bgColor: const Color(0xFFEDE9FE),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterFarmerScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "รายชื่อเกษตรกร",
          emoji: "📋",
          bgColor: const Color(0xFFFEF3C7),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FarmerListScreen()),
            );
          },
        ),
        _buildMenuCard(
          title: "ลงทะเบียนรถ",
          emoji: "🚗",
          bgColor: const Color(0xFFFEE2E2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterVehicleScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
         title: "บันทึกรับซื้อน้ำยาง",
  emoji: "💧",
  bgColor: const Color(0xFFE0F2FE),
  onTap: () {
    // ดึงเฉพาะตัวเลขราคารับซื้อออกจากสตริง (เช่น "฿55.0" -> 55.0)
    final cleanPriceText = _todayPrice.replaceAll('฿', '').trim();
    final double parsedPrice = double.tryParse(cleanPriceText) ?? 0.0;
    
    // ดึงวันที่ปัจจุบันในรูปแบบ YYYY-MM-DD สำหรับ priceId
    final String todayDateStr = DateTime.now().toIso8601String().split('T')[0];

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => PurchaseScreen(
          todayPrice: parsedPrice,
          priceId: todayDateStr,
        ),
      ),
    );
  },
),
        _buildMenuCard(
          title: "ตั้งราคาประจำวัน",
          emoji: "💰",
          bgColor: const Color(0xFFFEF9C3),
          onTap: () async {
            // เมื่อกดเข้าตั้งราคา เมื่อกลับมาหน้านี้จะทำการดึงราคานำมาอัปเดตทันที
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DailyPriceScreen()),
            );
            _fetchTodayPrice();
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String emoji,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return _HoverAnimatedCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Stateful Widget สำหรับลูกเล่น Hover เมนูด้านข้าง พร้อมแถบเส้นซ้าย
// -----------------------------------------------------------------
class _DrawerHoverItem extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String emoji;
  final String label;

  const _DrawerHoverItem({
    required this.isSelected,
    required this.onTap,
    required this.emoji,
    required this.label,
  });

  @override
  State<_DrawerHoverItem> createState() => _DrawerHoverItemState();
}

class _DrawerHoverItemState extends State<_DrawerHoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    if (widget.isSelected) {
      backgroundColor = const Color(0xFF2E6D52).withValues(alpha: 0.25);
    } else if (_isHovered) {
      backgroundColor = Colors.white.withValues(alpha: 0.08);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (widget.isSelected)
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E6D52),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ListTile(
              leading: Text(widget.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.white
                      : (_isHovered ? Colors.white : Colors.white70),
                  fontSize: 16,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
              dense: true,
              onTap: widget.onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Stateful Widget สำหรับลูกเล่น Hover ปุ่มออกจากระบบ
// -----------------------------------------------------------------
class _LogoutHoverItem extends StatefulWidget {
  final VoidCallback onTap;

  const _LogoutHoverItem({required this.onTap});

  @override
  State<_LogoutHoverItem> createState() => _LogoutHoverItemState();
}

class _LogoutHoverItemState extends State<_LogoutHoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.redAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: const Text("🚪", style: TextStyle(fontSize: 22)),
          title: const Text(
            "ออกจากระบบ",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Stateful Widget สำหรับลูกเล่น Hover / Animation การ์ดทั่วไป
// -----------------------------------------------------------------
class _HoverAnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverAnimatedCard({required this.child, this.onTap});

  @override
  State<_HoverAnimatedCard> createState() => _HoverAnimatedCardState();
}

class _HoverAnimatedCardState extends State<_HoverAnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: widget.child,
        ),
      ),
    );
  }
}
