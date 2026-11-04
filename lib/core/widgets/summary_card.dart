import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.title, required this.amount, required this.icon, this.color});
  final String title; final double amount; final IconData icon; final Color? color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color ?? Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(title, style: Theme.of(context).textTheme.labelLarge))]), const SizedBox(height: 8), Text(CurrencyFormatter.bdt(amount), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color))])));
}
