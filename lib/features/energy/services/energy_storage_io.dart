import 'dart:io';

/// Small key-value store for energy state on desktop/mobile targets.
///
/// The project does not currently use a persistence package, so this keeps the
/// energy timestamp in a tiny local file. The web implementation uses
/// localStorage through a conditional export.
class EnergyStorage {
  static final File _file = File('.tudlo_energy_state');

  static Future<Map<String, String>> read() async {
    if (!await _file.exists()) return {};
    final lines = await _file.readAsLines();
    return {
      for (final line in lines)
        if (line.contains('=')) _keyFor(line): _valueFor(line),
    };
  }

  static String _keyFor(String line) => line.substring(0, line.indexOf('='));

  static String _valueFor(String line) {
    return line.substring(line.indexOf('=') + 1);
  }

  static Future<void> write(Map<String, String> values) async {
    final lines = values.entries.map((entry) => '${entry.key}=${entry.value}');
    await _file.writeAsString(lines.join('\n'));
  }
}
