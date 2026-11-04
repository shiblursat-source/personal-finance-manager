import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(title: 'Personal Finance Manager', debugShowCheckedModeBanner: false, theme: AppTheme.light(), darkTheme: AppTheme.dark(), routerConfig: appRouter);
}
