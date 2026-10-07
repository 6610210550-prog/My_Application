class PurchaseRecord {
  final String farmerId;
  final double weightIn;
  final double weightOut;
  final double rubberWeight; 
  final double drc;          
  final double netWeight;    
  final String priceId;      
  final double totalPrice;   
  final String rubberType;   

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