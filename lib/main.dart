import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'tela_principal_com_abas.dart';
import 'theme_manager.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();

  final themeManager = ThemeManager();

  runApp(
    ChangeNotifierProvider(create: (context) => themeManager, child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeManager.themeMode,
          theme: themeManager.getLightTheme(),
          darkTheme: themeManager.getDarkTheme(),
          home: TelaPrincipalComAbas(),
        );
      },
    );
  }
}
