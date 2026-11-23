import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Wrapper penyimpanan database Web yang tahan terhadap blokir IndexedDB / Private Browsing Safari
class ResilientWebStorage implements DriftWebStorage {
  final DriftWebStorage _primary;
  DriftWebStorage? _fallback;
  bool _usingFallback = false;

  ResilientWebStorage({
    required DriftWebStorage primary,
  }) : _primary = primary;

  @override
  Future<void> open() async {
    try {
      await _primary.open();
    } catch (e) {
      debugPrint('ResilientWebStorage: primary storage open notice: $e');
      _usingFallback = true;
      _fallback = DriftWebStorage.volatile();
      await _fallback!.open();
    }
  }

  @override
  Future<void> close() async {
    if (_usingFallback) {
      await _fallback?.close();
    } else {
      try {
        await _primary.close();
      } catch (_) {}
    }
  }

  @override
  Future<Uint8List?> restore() async {
    if (_usingFallback) {
      return await _fallback?.restore();
    }
    try {
      return await _primary.restore();
    } catch (e) {
      debugPrint('ResilientWebStorage: primary restore notice: $e');
      _usingFallback = true;
      _fallback = DriftWebStorage.volatile();
      return await _fallback?.restore();
    }
  }

  @override
  Future<void> store(Uint8List data) async {
    if (_usingFallback) {
      await _fallback?.store(data);
      return;
    }
    try {
      await _primary.store(data);
    } catch (e) {
      debugPrint('ResilientWebStorage: primary store notice: $e');
      _usingFallback = true;
      _fallback = DriftWebStorage.volatile();
      await _fallback?.store(data);
    }
  }
}

/// Membuka koneksi web database untuk preview di browser Chrome / Web / Safari iOS.
DatabaseConnection openConnection() {
  return DatabaseConnection(
    WebDatabase.withStorage(
      ResilientWebStorage(
        primary: DriftWebStorage.indexedDb('myfinance_db', migrateFromLocalStorage: true),
      ),
      logStatements: kDebugMode,
    ),
  );
}
