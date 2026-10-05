class PurchaseRecord {
  final String farmerId;
  final double weightIn;
  final double weightOut;
  final double rubberWeight; // น้ำหนักยางสด
  final double drc;          // % DRC
  final double netWeight;    // น้ำหนักยางแห้ง
  final String priceId;      // วันที่อ้างอิงราคารับซื้อ (YYYY-MM-DD)
  final double totalPrice;   // ราคารวม
  final String rubberType;   // ประเภท (เช่น สด)

  PurchaseRecord({
    required this.farmerId,
    this.weightIn = 0.0,
    this.weightOut = 0.0,
    required this.rubberWeight,
    required this.drc,
    required this.netWeight,
    required this.priceId,
    required this.totalPrice,
    this.rubberType = 'สด',
  });

  Map<String, dynamic> toJson() => {
    'farmer_id': farmerId,
    'weight_in': weightIn,
    'weight_out': weightOut,
    'rubber_weight': rubberWeight,
    'drc': drc,
    'net_weight': netWeight,
    'price_id': priceId,
    'total_price': totalPrice,
    'rubber_type': rubberType,
  };
}