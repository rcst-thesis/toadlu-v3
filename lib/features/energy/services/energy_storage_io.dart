class EnergyStorage {
  static final Map<String, String> _store = {};

  static Future<Map<String, String>> read() async => Map.of(_store);

  static Future<void> write(Map<String, String> values) async {
    _store
      ..clear()
      ..addAll(values);
  }
}
