import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientations are applied in [BkReaderApp] from screen size
  // (phones: portrait; tablets/iPads: all orientations).
  await configureDependencies();
  runApp(const BkReaderApp());
}
