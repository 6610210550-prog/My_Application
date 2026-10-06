import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/test_model.dart';
import '../utils/result.dart';

class TestService {
  final String baseUrl = 'http://127.0.0.1:3000/api/test';

  // 📌 0. ดึงรายการรับซื้อที่ยังไม่ได้ตรวจคุณภาพ (สำหรับ Dropdown ในหน้า QualityTestScreen)
  Future<Result<List<PendingPurchase>>> getPendingPurchases() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pending-purchases'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          final purchases = list.map((item) => PendingPurchase.fromJson(item)).toList();
          return Result.ok(purchases);
        }
        return Result.error(Exception(data['message'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล'));
      }
      return Result.error(Exception('Server Error (${response.statusCode})'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 1. [Scope 1: Read] ดึงรายการผลการตรวจคุณภาพทั้งหมด
  Future<Result<List<TestRecord>>> getAllTests() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          final tests = list.map((item) => TestRecord.fromJson(item)).toList();
          return Result.ok(tests);
        }
        return Result.error(Exception(data['message'] ?? 'เกิดข้อผิดพลาดในการโหลดรายการ'));
      }
      return Result.error(Exception('Server Error (${response.statusCode})'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 2. [Scope 2: Create] บันทึกผลการตรวจคุณภาพ (saveTest)
  Future<Result<bool>> saveTest(TestRecord record) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Result.ok(true);
        }
        return Result.error(Exception(data['message'] ?? 'บันทึกข้อมูลไม่สำเร็จ'));
      }
      return Result.error(Exception('Server Error (${response.statusCode})'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 3. [Scope 3: Update] แก้ไขข้อมูลผลการตรวจคุณภาพ
  Future<Result<bool>> updateTest(int testId, TestRecord record) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$testId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Result.ok(true);
        }
        return Result.error(Exception(data['message'] ?? 'แก้ไขข้อมูลไม่สำเร็จ'));
      }
      return Result.error(Exception('Server Error (${response.statusCode})'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 4. [Scope 4: Delete] ลบข้อมูลผลการตรวจคุณภาพ
  Future<Result<bool>> deleteTest(int testId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$testId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Result.ok(true);
        }
        return Result.error(Exception(data['message'] ?? 'ลบข้อมูลไม่สำเร็จ'));
      }
      return Result.error(Exception('Server Error (${response.statusCode})'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 5. [Scope 5: Analytics] แสดงจำนวน Test แยกตาม Farmer
  Future<Result<List<Map<String, dynamic>>>> getTestCountByFarmer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/count-by-farmer'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<Map<String, dynamic>> summaryList =
              List<Map<String, dynamic>>.from(data['data']);
          return Result.ok(summaryList);
        }
        return Result.error(Exception(data['message'] ?? 'ดึงข้อมูลสถิติไม่สำเร็จ'));
      }
      return Result.error(Exception('Server Error (${response.statusCode})'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 6. ดึงรายการตรวจคุณภาพแยกตามเกษตรกร (ค้นหาด้วยชื่อ/รหัส)
  Future<Result<List<Map<String, dynamic>>>> getTestsByFarmer({String search = ''}) async {
    try {
      // 🟢 แก้ไข URL ไม่ให้ติด /api/test ซ้ำซ้อน
      final response = await http.get(
        Uri.parse('$baseUrl/by-farmer?search=$search'),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final List data = body['data'];
          return Result.ok(List<Map<String, dynamic>>.from(data));
        }
        return Result.error(Exception(body['message'] ?? 'ดึงข้อมูลประวัติไม่สำเร็จ'));
      }
      return Result.error(Exception('Server Error (${response.statusCode})'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}