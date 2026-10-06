import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/purchase_model.dart';
import '../utils/result.dart'; // โครงสร้าง Result<T> จาก WS12

class PurchaseService {
  final String baseUrl = 'http://127.0.0.1:3000/api';

  // 📌 1. [แสดง Purchase] ดึงรายการรับซื้อทั้งหมด
  Future<Result<List<Map<String, dynamic>>>> getAllPurchases() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/purchase'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          final purchases = list.map((item) => item as Map<String, dynamic>).toList();
          return Result.ok(purchases);
        }
      }
      return Result.error(Exception('ไม่สามารถดึงข้อมูลรายการรับซื้อได้'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 2. [เพิ่ม Purchase] บันทึกข้อมูลรายการรับซื้อ (ฟังก์ชันเดิมของคุณ)
  Future<Result<bool>> savePurchase(PurchaseRecord record) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchase/save_purchase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_id': record.farmerId,
          'weight_in': record.weightIn,
          'weight_out': record.weightOut,
          'rubber_weight': record.rubberWeight,
          'drc': record.drc,
          'net_weight': record.netWeight,
          'price_id': record.priceId,
          'total_price': record.totalPrice,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isError'] == false || data['success'] == true) {
          return Result.ok(true);
        }
      }
      return Result.error(Exception('เกิดข้อผิดพลาดในการบันทึก'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 3. [แก้ไข Purchase] แก้ไขข้อมูลรายการรับซื้อ
  Future<Result<bool>> updatePurchase(String purchaseId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/purchase/$purchaseId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Result.ok(true);
        }
      }
      return Result.error(Exception('เกิดข้อผิดพลาดในการแก้ไขข้อมูล'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 4. [ลบ Purchase] ลบข้อมูลรายการรับซื้อ
  Future<Result<bool>> deletePurchase(String purchaseId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/purchase/$purchaseId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Result.ok(true);
        }
      }
      return Result.error(Exception('เกิดข้อผิดพลาดในการลบข้อมูล'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // 📌 5. [แสดงจำนวน Purchase แยกตาม Price] ดึงสถิติตามราคารับซื้อ
  Future<Result<List<Map<String, dynamic>>>> getPurchaseCountByPrice() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/purchase/count-by-price'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final List list = data['data'];
        final resultList = list.map((item) => item as Map<String, dynamic>).toList();
        return Result.ok(resultList);
      }
    }
    return Result.error(Exception('ไม่สามารถดึงข้อมูลสถิติตามราคาได้'));
  } catch (e) {
    return Result.error(Exception(e.toString()));
  }
}

  // 📌 ดึงข้อมูลรถ (ฟังก์ชันเดิมของคุณ)
  Future<Result<List<Map<String, dynamic>>>> getVehicles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/car/get_all_cars'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isError'] == false && data['data'] != null) {
          final List list = data['data'];
          final vehicles = list.map((item) => item as Map<String, dynamic>).toList();
          return Result.ok(vehicles);
        }
      }
      return Result.error(Exception('ไม่สามารถดึงข้อมูลรถได้'));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}