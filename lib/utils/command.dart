import 'package:flutter/foundation.dart';
import 'result.dart';

typedef CommandAction1<T, P> = Future<Result<T>> Function(P param);

class Command1<T, P> extends ChangeNotifier {
  final CommandAction1<T, P> _action;
  bool _running = false;

  Command1(this._action);

  bool get running => _running;

  Future<Result<T>> execute(P param) async {
    if (_running) return Error(Exception('Action in progress'));
    
    _running = true;
    notifyListeners();

    try {
      final result = await _action(param);
      return result;
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}