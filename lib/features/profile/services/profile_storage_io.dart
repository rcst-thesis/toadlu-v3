import 'dart:io';

class ProfileStorage {
  static final File _file = File('.tudlo_profiles_state');

  static Future<String> read() async {
    if (!await _file.exists()) return '';
    return _file.readAsString();
  }

  static Future<void> write(String value) async {
    await _file.writeAsString(value);
  }
}
