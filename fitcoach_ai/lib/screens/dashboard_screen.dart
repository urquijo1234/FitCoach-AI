import 'package:fitcoach_ai/providers/user_profile_provider.dart';
import 'package:fitcoach_ai/providers/weekly_plan_provider.dart';
import 'package:fitcoach_ai/screens/daily_routine_screen.dart';
import 'package:fitcoach_ai/widgets/macro_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePlan());
  }

  Future<void> _ensurePlan() async {
    final profile = context.read<UserProfileProvider>().profile;
    if (profile == null) return;
    final provider = context.read<WeeklyPlanProvider>();
    if (provider.weeklyPlan == null && !provider.isLoading) {
      await provider.generatePlan(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyPlan = context.watch<WeeklyPlanProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildState(weeklyPlan),
      ),
    );
  }

  Widget _buildState(WeeklyPlanProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.weeklyPlan == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _ensurePlan, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final plan = provider.weeklyPlan;
    if (plan == null) {
      return const Center(child: Text('No hay plan disponible todavía.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MacroSummaryCard(diet: plan.diet),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyRoutineScreen()),
          ),
          icon: const Icon(Icons.fitness_center),
          label: const Text('Ver Rutina de Hoy'),
        ),
      ],
    );
  }
}
