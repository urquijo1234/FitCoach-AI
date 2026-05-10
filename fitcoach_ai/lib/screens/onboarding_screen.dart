import 'package:fitcoach_ai/models/user_profile.dart';
import 'package:fitcoach_ai/providers/auth_provider.dart';
import 'package:fitcoach_ai/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _allergies = TextEditingController();
  final _injuries = TextEditingController();
  String _gender = 'masculino';
  String _goal = 'mantenimiento';
  int _days = 3;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final provider = context.watch<UserProfileProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _num(_age, 'Edad', 14, 80),
            _num(_weight, 'Peso (kg)', 30, 250, decimal: true),
            _num(_height, 'Altura (cm)', 100, 230, decimal: true),
            DropdownButtonFormField(value: _gender, items: const [
              DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
              DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ], onChanged: (v) => setState(() => _gender = v!)),
            DropdownButtonFormField(value: _goal, items: const [
              DropdownMenuItem(value: 'volumen', child: Text('Volumen')),
              DropdownMenuItem(value: 'definicion', child: Text('Definición')),
              DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
              DropdownMenuItem(value: 'perdida_de_peso', child: Text('Pérdida de peso')),
              DropdownMenuItem(value: 'resistencia', child: Text('Resistencia')),
            ], onChanged: (v) => setState(() => _goal = v!)),
            DropdownButtonFormField<int>(value: _days, items: [3,4,5,6].map((d)=>DropdownMenuItem(value:d, child:Text('$d días/semana'))).toList(), onChanged: (v)=>setState(()=>_days=v!)),
            TextFormField(controller: _allergies, decoration: const InputDecoration(labelText: 'Alergias (separadas por coma)')),
            TextFormField(controller: _injuries, decoration: const InputDecoration(labelText: 'Lesiones (separadas por coma)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: provider.isLoading ? null : () async {
              if (!_formKey.currentState!.validate()) return;
              final user = auth.user;
              if (user == null) return;
              final now = DateTime.now().toUtc();
              final profile = UserProfile(
                uid: user.uid,
                email: user.email ?? '',
                age: int.parse(_age.text.trim()),
                gender: _gender,
                weightKg: double.parse(_weight.text.trim()),
                heightCm: double.parse(_height.text.trim()),
                goal: _goal,
                trainingDaysPerWeek: _days,
                allergies: _csv(_allergies.text),
                injuries: _csv(_injuries.text),
                onboardingCompleted: true,
                createdAt: provider.profile?.createdAt ?? now,
                updatedAt: now,
              );
              final ok = await provider.saveProfile(profile);
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'No se pudo guardar')));
                return;
              }
              Navigator.pushReplacementNamed(context, '/dashboard');
            }, child: const Text('Guardar y continuar'))
          ]),
        ),
      ),
    );
  }

  TextFormField _num(TextEditingController c, String l, num min, num max, {bool decimal=false}) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: l),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return '$l es obligatorio';
      final n = decimal ? double.tryParse(v.trim()) : int.tryParse(v.trim());
      if (n == null) return '$l inválido';
      if (n < min || n > max) return '$l debe estar entre $min y $max';
      return null;
    },
  );

  List<String> _csv(String raw) => raw.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
}
