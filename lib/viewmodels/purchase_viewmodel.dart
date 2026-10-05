import 'package:flutter/foundation.dart';
import '../models/purchase_model.dart';
import '../repositories/purchase_repository.dart';
import '../utils/command.dart';
import '../utils/result.dart';

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseRepository _repository;

  PurchaseViewModel({required PurchaseRepository repository})
      : _repository = repository {
    savePurchaseCommand = Command1(_savePurchase);
  }

  late Command1<void, PurchaseRecord> savePurchaseCommand;

  double _calculatedRubberWeight = 0.0; // น้ำหนักยางสด
  double _calculatedNetWeight = 0.0;    // น้ำหนักยางแห้ง
  double _calculatedTotalPrice = 0.0;   // ราคารวม

  double get calculatedRubberWeight => _calculatedRubberWeight;
  double get calculatedNetWeight => _calculatedNetWeight;
  double get calculatedTotalPrice => _calculatedTotalPrice;

  // 📌 คำนวณน้ำหนักสด, น้ำหนักแห้ง, และ ราคารวมแบบ Real-time
  void calculate({
    required double weightIn,
    required double weightOut,
    required double drc,
    required double buyPrice,
  }) {
    if (weightIn > 0 && weightOut >= 0 && weightIn > weightOut) {
      _calculatedRubberWeight = _repository.calculateRubberWeight(weightIn, weightOut);
      _calculatedNetWeight = _repository.calculateNetWeight(_calculatedRubberWeight, drc);
      _calculatedTotalPrice = _repository.calculateTotalPrice(_calculatedNetWeight, buyPrice);
    } else {
      _calculatedRubberWeight = 0.0;
      _calculatedNetWeight = 0.0;
      _calculatedTotalPrice = 0.0;
    }
    notifyListeners();
  }

  Future<Result<void>> _savePurchase(PurchaseRecord record) async {
    final result = await _repository.submitPurchase(record);
    if (result is Ok<bool>) {
      return Result.ok(null);
    } else if (result is Error<bool>) {
      return Result.error(result.error);
    } else {
      return Result.error(Exception('Unknown error'));
    }
  }
}