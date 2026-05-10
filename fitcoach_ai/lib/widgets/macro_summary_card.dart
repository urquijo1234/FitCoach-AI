import 'package:fitcoach_ai/models/weekly_plan.dart';
import 'package:flutter/material.dart';

class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard({super.key, required this.diet});

  final Diet diet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de dieta de hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('${diet.dailyCalories} kcal', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _macro('Proteína', '${diet.macros.proteinG} g', Colors.redAccent),
                _macro('Carbs', '${diet.macros.carbsG} g', Colors.blueAccent),
                _macro('Grasas', '${diet.macros.fatG} g', Colors.orangeAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
