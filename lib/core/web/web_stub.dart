/// Stub implementation for web APIs when not running on web platform
/// This file is used when `dart.library.html` is NOT available
// ignore_for_file: library_private_types_in_public_api

library;

// Stub for web.Storage
class _StorageStub {
  String? operator [](String key) => null;
  void operator []=(String key, String value) {}
  void removeItem(String key) {}
}

// Stub for web.window
class _WindowStub {
  final _LocationStub location = _LocationStub();
  final _StorageStub sessionStorage = _StorageStub();
  final _StorageStub localStorage = _StorageStub();
}

class _LocationStub {
  String get href => '';
}

final _WindowStub window = _WindowStub();
