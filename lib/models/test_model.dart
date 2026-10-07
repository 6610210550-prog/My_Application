// lib/models/test_model.dart

class TestRecord {
  final int? testId;
  final String purchaseId;
  final double? ammonia;
  final double? vfa;
  final double? magnesium;
  final double? drc;
  final String? testDate;
  final String resultStatus;
  final String resultApprove;
  final int? accountId;
  final String? farmerName;
  final double? rubberWeight;
  final String? testerName;

  TestRecord({
    this.testId,
    required this.purchaseId,
    this.ammonia,
    this.vfa,
    this.magnesium,
    this.drc,
    this.testDate,
    this.resultStatus = 'PASS',
    this.resultApprove = 'PENDING',
    this.accountId,
    this.farmerName,
    this.rubberWeight,
    this.testerName,
  });

  // 📌 แปลงจาก JSON (Map) เป็น TestRecord Object
  factory TestRecord.fromJson(Map<String, dynamic> json) {
    return TestRecord(
      testId: json['test_id'] != null ? int.tryParse(json['test_id'].toString()) : null,
      purchaseId: json['purchase_id'] != null ? json['purchase_id'].toString() : '',
      ammonia: json['ammonia'] != null ? double.tryParse(json['ammonia'].toString()) : null,
      vfa: json['vfa'] != null ? double.tryParse(json['vfa'].toString()) : null,
      magnesium: json['magnesium'] != null ? double.tryParse(json['magnesium'].toString()) : null,
      drc: json['drc'] != null ? double.tryParse(json['drc'].toString()) : null,
      testDate: json['test_date']?.toString(),
      resultStatus: json['result_status']?.toString() ?? 'PASS',
      resultApprove: json['result_approve']?.toString() ?? 'PENDING',
      accountId: json['account_id'] != null ? int.tryParse(json['account_id'].toString()) : null,
      farmerName: json['farmer_name']?.toString(),
      rubberWeight: json['rubber_weight'] != null ? double.tryParse(json['rubber_weight'].toString()) : null,
      testerName: json['tester_name']?.toString(),
    );
  }

  // 📌 แปลงจาก TestRecord Object เป็น JSON (Map) สำหรับส่งไป Backend
  Map<String, dynamic> toJson() {
    return {
      if (testId != null) 'test_id': testId,
      'purchase_id': purchaseId,
      'ammonia': ammonia,
      'vfa': vfa,
      'magnesium': magnesium,
      'drc': drc,
      if (testDate != null) 'test_date': testDate,
      'result_status': resultStatus,
      'result_approve': resultApprove,
      'account_id': accountId,
    };
  }
}

class PendingPurchase {
  final String purchaseId;
  final String farmerId;
  final String farmerName;
  final double rubberWeight;
  final double? purchaseDrc;
  final double totalPrice;
  final String purchaseDate;

  PendingPurchase({
    required this.purchaseId,
    required this.farmerId,
    required this.farmerName,
    required this.rubberWeight,
    this.purchaseDrc,
    required this.totalPrice,
    required this.purchaseDate,
  });

  factory PendingPurchase.fromJson(Map<String, dynamic> json) {
    // ฟังก์ชันช่วยแปลงค่า ID กรณีที่ส่งมาเป็น string เช่น "PU00000001" หรือตัวเลข
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      final str = val.toString();
      // ลบตัวอักษรที่ไม่ใช่ตัวเลขออก (เช่น PU00000001 -> 1)
      final cleanStr = str.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleanStr) ?? 0;
    }

    return PendingPurchase(
      purchaseId: json['purchase_id']?.toString() ?? '', 
      farmerId: json['farmer_id']?.toString() ?? '',
      farmerName: json['farmer_name']?.toString() ?? '',
      rubberWeight: json['rubber_weight'] != null 
          ? double.tryParse(json['rubber_weight'].toString()) ?? 0.0 
          : 0.0,
      purchaseDrc: json['purchase_drc'] != null 
          ? double.tryParse(json['purchase_drc'].toString()) 
          : null,
      totalPrice: json['total_price'] != null 
          ? double.tryParse(json['total_price'].toString()) ?? 0.0 
          : 0.0,
      purchaseDate: json['purchase_date']?.toString() ?? '',
    );
  }
}

class FarmerTestSummaryModel {
  final String farmerId;
  final String farmerName;
  final int totalTests;
  final double avgDrc;

  FarmerTestSummaryModel({
    required this.farmerId,
    required this.farmerName,
    required this.totalTests,
    required this.avgDrc,
  });

  factory FarmerTestSummaryModel.fromJson(Map<String, dynamic> json) {
    return FarmerTestSummaryModel(
      farmerId: json['farmer_id'] ?? '',
      farmerName: json['farmer_name'] ?? '',
      totalTests: int.tryParse(json['total_tests'].toString()) ?? 0,
      avgDrc: double.tryParse(json['avg_drc'].toString()) ?? 0.0,
    );
  }
}