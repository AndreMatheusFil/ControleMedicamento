import 'package:flutter/material.dart';
// import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/home_page.dart';
import 'package:controlemedicamento/ui/app_theme.dart';

void main() async {
  
  // await initializeDateFormatting("pt_BR", null); // inicializa locale
  runApp(MaterialApp(
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate
    ],
    supportedLocales: [const Locale('pt', 'BR')],
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    title: "Controle de Medicamentos",
    home: HomePage()
  ));
}