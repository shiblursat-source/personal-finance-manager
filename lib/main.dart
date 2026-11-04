import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/providers.dart';
import 'data/seed_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final db = container.read(appDatabaseProvider);
  await SeedDataService(db).seedIfEmpty();
  runApp(UncontrolledProviderScope(container: container, child: const FinanceApp()));
}
