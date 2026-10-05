import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/config/app_config.dart';
import 'package:flutter_application_1/untils/date_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:async'; // บรรทัดสำคัญ: ใช้คุมเวลาการลูปพิมพ์ดีด
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameValueController = TextEditingController();
  final _passwordValueController = TextEditingController();

  bool _isHovered = false; 

  // --- 🟢 ตัวแปรสำหรับคุมลูกเล่นพิมพ์ข้อความทีละคำแบบวนลูป ---
  final String _targetText = "ระบบรับซื้อน้ำยาง";
  String _displayedText = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _startTypewriterEffect();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel(); // ล้างหน่วยความจำเมื่อปิดหน้าจอ
    _usernameValueController.dispose();
    _passwordValueController.dispose();
    super.dispose();
  }

  // ฟังก์ชันพิมพ์ดีดเวอร์ชันอัปเกรด: พิมพ์จบ รอ 3 วิ แล้วเริ่มใหม่
  void _startTypewriterEffect() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_charIndex < _targetText.length) {
        setState(() {
          _displayedText += _targetText[_charIndex];
          _charIndex++;
        });
      } else {
        // พิมพ์ครบคำแล้ว! สั่งหยุด Timer ปัจจุบันก่อน
        _typewriterTimer?.cancel();
        
        // สั่งให้รอ 3 วินาที แล้วค่อยเคลียร์ค่าเริ่มต้นพิมพ์ใหม่
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) { // เช็กเผื่อผู้ใช้เปลี่ยนหน้าไปก่อน
            setState(() {
              _displayedText = "";
              _charIndex = 0;
            });
            _startTypewriterEffect(); // สั่งให้เริ่มพิมพ์ดีดใหม่อีกรอบ (ลูป)
          }
        });
      }
    });
  }

  Future<(bool, String, String)> _authenRequest() async {
    String username = _usernameValueController.text;
    DateTime now = DateTime.now();
    String formattedDateString = DateUtil.getFormattedDate(now);

    String combinedString = "$username&$formattedDateString";
    print(combinedString);

    String authenRequestString = sha256
        .convert(utf8.encode(combinedString))
        .toString();
    print("authenRequestString: $authenRequestString");
    final response = await http.post(
      Uri.parse("${Appconfig.apiBaseUrl}/authen/authen_request"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'authen_request': authenRequestString}),
    );

    final json = jsonDecode(response.body);

    print(json);

    return (
      json["isError"] as bool,
      json["data"] as String,
      json["errorMessage"] as String,
    );
  }

  Future<({bool isError, String data , String errorMessage})> _accessRequest(
    String authenToken,
  ) async {
    String username = _usernameValueController.text;
    String password = _passwordValueController.text;
    String passwordEncode = sha256.convert(utf8.encode(password)).toString();
    String combinedString = "$username&$passwordEncode&$authenToken";
    String authenSignature = sha256.convert(utf8.encode(combinedString)).toString();

    print(combinedString);
    print(authenSignature);

    final response = await http.post(
      Uri.parse("${Appconfig.apiBaseUrl}/authen/access_request"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'authen_signature': authenSignature,
        'authen_token': authenToken
      }),
    );

    final json = jsonDecode(response.body);
    print(json);

    if(!json["isError"]) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("access_token", json["data"]["access_token"]);
      await prefs.setString("username",_usernameValueController.text);
      
    }

    return (
      isError: json["isError"] as bool,
      data: json["data"]["access_token"] as String,
      errorMessage: json["errorMessage"] as String,
    );
  }

  void _doLogin(BuildContext context) async {
    var (isError, authenToken, errorMessage) = await _authenRequest();
    print("authenToken: $authenToken");

    if (isError) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cancel_rounded,
                          color: Colors.red.shade600,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        errorMessage.isEmpty ? "ไม่พบข้อมูลผู้ใช้งานระบบ" : errorMessage,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xCC000000), // ค่านี้เทียบเท่ากับ Colors.black80 แต่เป็น const
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "กรุณาตรวจสอบ Username อีกครั้ง",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "ลองใหม่",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );    
    } else {
      var result = await _accessRequest(authenToken);
      print("access_token: ${result.data}");
print("result.isError = ${result.isError}");
      
      if (result.isError) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cancel_rounded,
                            color: Colors.red.shade600,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          result.errorMessage.isEmpty ? "รหัสผ่านไม่ถูกต้อง" : result.errorMessage,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xCC000000), // ค่านี้เทียบเท่ากับ Colors.black80 แต่เป็น const
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "กรุณาตรวจสอบรหัสผ่านของคุณอีกครั้ง",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "ลองใหม่",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
     } else {
        // --- ส่วนที่แก้ไข: เพิ่มการ Navigator ไปยัง HomeScreen ---
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green.shade600,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "เข้าสู่ระบบสำเร็จ !",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xCC000000),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "ยินดีต้อนรับเข้าสู่ระบบงานของคุณ",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              // ปิด Dialog
                              Navigator.pop(context);
                              // เปลี่ยนหน้าไปที่ HomeScreen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "ตกลง",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("BUILD LOGIN SCREEN");
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/pr1.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1.0 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayedText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 3),
                          blurRadius: 6,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28), 
                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 450),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 25,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "WELCOME",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Please sign in to continue",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              TextFormField(
                                controller: _usernameValueController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Username",
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอก Username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              TextFormField(
                                obscureText: true,
                                controller: _passwordValueController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอก Password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (event) => setState(() => _isHovered = true),
                                onExit: (event) => setState(() => _isHovered = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: 50,
                                  transform: _isHovered 
                                      ? (Matrix4.identity()..scale(1.03)) 
                                      : Matrix4.identity(),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isHovered 
                                            ? Colors.white.withOpacity(0.4) 
                                            : Colors.black.withOpacity(0.1),
                                        blurRadius: _isHovered ? 15 : 4,
                                        spreadRadius: _isHovered ? 2 : 0,
                                        offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        _doLogin(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.green.shade800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "LOGIN",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
