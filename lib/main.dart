import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/tudlo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TudloApp());
}
