import 'package:fitcoach_ai/models/weekly_plan.dart';
import 'package:flutter/material.dart';

class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard({super.key, required this.diet});

  final Diet diet;

  @override
  Widget build(BuildContext context) {
    const consumedRatio = 0.82;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de dieta de hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text('${diet.dailyCalories} kcal', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: consumedRatio,
                minHeight: 9,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrangeAccent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consumo ideal: ${(consumedRatio * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _macro(Icons.fitness_center, 'Proteína', '${diet.macros.proteinG} g', Colors.redAccent),
                _macro(Icons.grain, 'Carbs', '${diet.macros.carbsG} g', Colors.blueAccent),
                _macro(Icons.opacity, 'Grasas', '${diet.macros.fatG} g', Colors.orangeAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
