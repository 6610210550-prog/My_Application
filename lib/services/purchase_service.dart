import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/purchase_model.dart';
import '../utils/result.dart'; // โครงสร้าง Result<T> จาก WS12

class PurchaseService {
  final String baseUrl = 'http://127.0.0.1:3000/api';

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
      if (data['isError'] == false) {
        return Result.ok(true);
      }
    }
    return Result.error(Exception('เกิดข้อผิดพลาดในการบันทึก'));
  } catch (e) {
    return Result.error(Exception(e.toString()));
  }
}

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