/// Stub implementation for web APIs when not running on web platform
/// This file is used when `dart.library.html` is NOT available

// Stub for web.Storage
class _StorageStub {
  String? operator [](String key) => null;
  void operator []=(String key, String value) {}
}

// Stub for web.window
class _WindowStub {
  final _LocationStub location = _LocationStub();
  final _StorageStub sessionStorage = _StorageStub();
}

class _LocationStub {
  String get href => '';
}

final _WindowStub window = _WindowStub();
