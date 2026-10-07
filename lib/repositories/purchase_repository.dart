import '../models/purchase_model.dart';
import '../services/purchase_service.dart';
import '../utils/result.dart';

class PurchaseRepository {
  final PurchaseService _service;

  PurchaseRepository({required PurchaseService service}) : _service = service;

  // คำนวณน้ำหนักยางสด (rubber_weight = weight_in - weight_out)
  double calculateRubberWeight(double weightIn, double weightOut) {
    final result = weightIn - weightOut;
    return result > 0 ? result : 0.0;
  }

  // คำนวณน้ำหนักยางแห้งจริง (net_weight)
  double calculateNetWeight(double rubberWeight, double drc) {
    return rubberWeight * (drc / 100);
  }

  // คำนวณราคารวมทั้งสิ้น (total_price)
  double calculateTotalPrice(double netWeight, double buyPrice) {
    return netWeight * buyPrice;
  }

  // ส่งข้อมูลไปบันทึกผ่าน Service
  Future<Result<bool>> submitPurchase(PurchaseRecord record) async {
    return await _service.savePurchase(record);
  }
}