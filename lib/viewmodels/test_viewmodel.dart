import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../utils/result.dart';

class TestViewModel extends ChangeNotifier {
  final TestService _testService = TestService();
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // แจ้งเตือน UI ให้รีเฟรชเมื่อค่า loading เปลี่ยนแปลง
  }

  List<TestRecord> _testList = [];
  List<Map<String, dynamic>> _farmerAnalytics = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TestRecord> get testList => _testList;
  List<Map<String, dynamic>> get farmerAnalytics => _farmerAnalytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 📌 1. ดึงรายการตรวจทั้งหมด (Read)
  Future<void> fetchAllTests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _testService.getAllTests();

    switch (result) {
      case Ok(:final value):
        _testList = value;
      case Error(:final error):
        _errorMessage = error.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 📌 2. ลบข้อมูลการตรวจ (Delete)
  Future<bool> deleteTestRecord(int testId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _testService.deleteTest(testId);
    bool success = false;

    switch (result) {
      case Ok():
        _testList.removeWhere((item) => item.testId == testId);
        success = true;
      case Error(:final error):
        _errorMessage = error.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // 📌 3. ดึงสถิติจำนวนการตรวจแยกตาม Farmer (Analytics)
  Future<void> fetchFarmerAnalytics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _testService.getTestCountByFarmer();

    switch (result) {
      case Ok(:final value):
        _farmerAnalytics = value;
      case Error(:final error):
        _errorMessage = error.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateTest(int testId, TestRecord record) async {
  _setLoading(true);
  final result = await _testService.updateTest(testId, record);
  _setLoading(false);

  switch (result) {
    case Ok():
      await fetchAllTests(); // โหลดข้อมูลรายการใหม่หลังอัปเดตสำเร็จ
      return true;
    case Error(:final error):
      _errorMessage = error.toString();
      notifyListeners();
      return false;
  }
}
}