import 'package:flutter/material.dart';

import 'package:tudlo/core/theme/app_colors.dart';
import 'package:tudlo/features/startup/presentation/startup_flow.dart';

class TudloApp extends StatelessWidget {
  const TudloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tudlo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ComicRelief',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
        scaffoldBackgroundColor: AppColors.mint,
        useMaterial3: true,
      ),
      home: const StartupFlow(),
    );
  }
}
