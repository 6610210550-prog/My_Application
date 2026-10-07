import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_price_screen.dart';
import 'farmer_list_screen.dart';
import 'login_screen.dart';
import 'register_farmer_screen.dart';
import 'views/purchase_list_screen.dart';
import 'views/purchase_screen.dart';
import 'views/quality_test_screen.dart';
import 'views/test_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = "";
  String _todayPrice = "-";

  // สำหรับสไลด์ Banner อัตโนมัติ
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  final List<String> _bannerImages = ['assets/banner.png', 'assets/t1.jpg' , 'assets/t2.jpg' , 'assets/t3.jpg' , 'assets/pr1.jpg'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTodayPrice();
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString("username") ?? "ผู้ใช้งาน";
    });
  }

  // ดึงราคาของวันนี้จาก API Backend
  Future<void> _fetchTodayPrice() async {
    final url = Uri.parse("http://127.0.0.1:3000/api/price/get_today_price");
    try {
      final response = await http.get(url);
      if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        _todayPrice = "-";
      });
    }
  }

  // สลับภาพอัตโนมัติทุกๆ 3 วินาที
  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _bannerController.hasClients) {
        int currentPage = _bannerController.page?.round() ?? 0;
        int nextPage = (currentPage + 1) % _bannerImages.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      // AppBar ด้านบน
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // เมนูสไลด์ด้านข้าง (Drawer)
      drawer: _buildAppDrawer(currentIndex: 0),

      // เนื้อหาหน้าหลัก
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📌 ข้อความต้อนรับ (ปรับเข้มขึ้น + ถอดอิโมจิออก)
                Row(
                  children: [
                    const Text(
                      "ยินดีต้อนรับ",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2538), // เข้มชัดระดับเดียวกับหัวข้อหลัก
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Banner รูปภาพ
                _buildInteractiveBanner(),

                const SizedBox(height: 20),

                // 2. แดชบอร์ดสรุปผล
                const Text(
                  "แดชบอร์ดสรุปผล",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2538),
                  ),
                ),
                const SizedBox(height: 12),
                _buildHorizontalDashboardGrid(screenWidth),

                const SizedBox(height: 24),

                // 3. เมนูการใช้งานหลัก
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
  // Drawer (เมนูสไลด์ด้านข้าง)
  // -----------------------------------------------------------------
  Widget _buildAppDrawer({required int currentIndex}) {
    return Drawer(
      elevation: 0,
      child: Container(
        color: const Color(0xFF0F172A), // Dark Slate Background
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header Card แสดงรูปโลโก้ / โปรไฟล์ (tar.jpg)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    // กรอบรูปภาพ
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF2563EB),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/tar.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.business_rounded,
                            size: 26,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "บริษัท พัทลุงพาราเท็กซ์ จำกัด",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "ระบบจัดการน้ำยาง",
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 2. รายการเมนูหลักทั้งหมด
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildDrawerItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.grid_view_rounded,
                      label: "หน้าหลัก",
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.person_add_alt_1_rounded,
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
                      icon: Icons.people_alt_rounded,
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
                      icon: Icons.water_drop_rounded,
                      label: "บันทึกการรับซื้อน้ำยาง",
                      onTap: () {
                        Navigator.pop(context);
                        final cleanPriceText =
                            _todayPrice.replaceAll('฿', '').trim();
                        final double parsedPrice =
                            double.tryParse(cleanPriceText) ?? 0.0;
                        final String todayDateStr =
                            DateTime.now().toIso8601String().split('T')[0];

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
                      index: 4,
                      currentIndex: currentIndex,
                      icon: Icons.receipt_long_rounded,
                      label: "รายการรับซื้อน้ำยาง",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PurchaseListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      index: 5,
                      currentIndex: currentIndex,
                      icon: Icons.science_rounded,
                      label: "ตรวจคุณภาพน้ำยาง",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QualityTestScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      index: 6,
                      currentIndex: currentIndex,
                      icon: Icons.analytics_rounded,
                      label: "รายการผลการตรวจ",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TestListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      index: 7,
                      currentIndex: currentIndex,
                      icon: Icons.price_change_rounded,
                      label: "ตั้งราคาประจำวัน",
                      onTap: () async {
                        Navigator.pop(context);
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

              // 3. ปุ่มออกจากระบบ (ล้างข้อมูลและเด้งกลับหน้า LoginScreen)
              _LogoutHoverItem(
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (!mounted) return;

                  // สั่งกลับไปหน้า LoginScreen พร้อมลบประวัติการท่องหน้าจอก่อนหน้าทั้งหมด
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    bool isSelected = index == currentIndex;
    return _DrawerHoverItem(
      isSelected: isSelected,
      onTap: onTap,
      icon: icon,
      label: label,
    );
  }

  // -----------------------------------------------------------------
  // Banner รูปภาพ
  // -----------------------------------------------------------------
  Widget _buildInteractiveBanner() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3.2,
          child: Container(
            width: double.infinity,
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
                scrollBehavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                  },
                ),
                onPageChanged: (index) {
                  setState(() => _currentBannerIndex = index);
                },
                itemCount: _bannerImages.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    _bannerImages[index],
                    fit: BoxFit.fitWidth,
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
  // แดชบอร์ดสรุปผล
  // -----------------------------------------------------------------
  Widget _buildHorizontalDashboardGrid(double screenWidth) {
    int crossAxisCount = screenWidth < 600 ? 2 : 4;
    double aspectRatio = screenWidth < 600 ? 1.3 : 1.1;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
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
          value: _todayPrice,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // เมนูลัดการใช้งาน
  // -----------------------------------------------------------------
  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMenuCard(
          title: "ลงทะเบียนเกษตรกร",
          icon: Icons.person_add_rounded,
          iconColor: const Color(0xFF7C3AED),
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
          icon: Icons.badge_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FarmerListScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "บันทึกการรับซื้อน้ำยาง",
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFF0284C7),
          bgColor: const Color(0xFFE0F2FE),
          onTap: () {
            final cleanPriceText = _todayPrice.replaceAll('฿', '').trim();
            final double parsedPrice = double.tryParse(cleanPriceText) ?? 0.0;
            final String todayDateStr =
                DateTime.now().toIso8601String().split('T')[0];

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
          title: "รายการรับซื้อน้ำยาง",
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF475569),
          bgColor: const Color(0xFFF1F5F9),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PurchaseListScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "ตรวจคุณภาพน้ำยาง",
          icon: Icons.science_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFE0FDF4),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QualityTestScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "รายการผลการตรวจ",
          icon: Icons.analytics_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFF0F9FF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TestListScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "ตั้งราคาประจำวัน",
          icon: Icons.payments_rounded,
          iconColor: const Color(0xFFCA8A04),
          bgColor: const Color(0xFFFEF9C3),
          onTap: () async {
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
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color iconColor,
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
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Widget สำหรับ Hover รายการเมนูใน Drawer
// -----------------------------------------------------------------
class _DrawerHoverItem extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _DrawerHoverItem({
    required this.isSelected,
    required this.onTap,
    required this.icon,
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
      backgroundColor = const Color(0xFF2563EB);
    } else if (_isHovered) {
      backgroundColor = Colors.white.withOpacity(0.08);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Icon(
            widget.icon,
            color: widget.isSelected
                ? Colors.white
                : (_isHovered
                    ? Colors.white
                    : const Color(0xFF94A3B8)),
            size: 20,
          ),
          title: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? Colors.white
                  : (_isHovered
                      ? Colors.white
                      : const Color(0xFFE2E8F0)),
              fontSize: 14,
              fontWeight:
                  widget.isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Widget สำหรับ Hover ปุ่มออกจากระบบ
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.redAccent.withOpacity(0.18)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.redAccent.withOpacity(_isHovered ? 0.4 : 0.2),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFF87171),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "ออกจากระบบ",
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Widget สำหรับ Hover / Animation ของการ์ด
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
          borderRadius: BorderRadius.circular(10),
          child: widget.child,
        ),
      ),
    );
  }
}