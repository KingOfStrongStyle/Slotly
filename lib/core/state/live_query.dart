import 'package:flutter/foundation.dart';

class LiveQuery<T> extends ChangeNotifier {
  LiveQuery(this._load, {this._refreshOn}) {
    _refreshOn?.addListener(_onSourceChanged);
  }

  final Future<T> Function() _load;
  final Listenable? _refreshOn;
  T? _data;
  Object? _error;
  bool _isLoading = false;
  bool _isDisposed = false;

  int _requestId = 0;

  T? get data => _data;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get hasData => _data != null;

  Future<void> load() async {
    final requestId = ++_requestId;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _load();
      if (_isDisposed || requestId != _requestId) return;
      _data = result;
      _error = null;
    } on Exception catch (error) {
      if (_isDisposed || requestId != _requestId) return;
      _error = error;
    }
    _isLoading = false;
    notifyListeners();
  }

  void _onSourceChanged() => load();

  @override
  void dispose() {
    _isDisposed = true;
    _refreshOn?.removeListener(_onSourceChanged);
    super.dispose();
  }
}
