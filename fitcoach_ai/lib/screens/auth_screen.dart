import 'package:fitcoach_ai/providers/auth_provider.dart';
import 'package:fitcoach_ai/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routeName = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final userProfileProvider = context.read<UserProfileProvider>();

    final ok = _isLoginMode
        ? await auth.login(email: _emailController.text.trim(), password: _passwordController.text)
        : await auth.register(email: _emailController.text.trim(), password: _passwordController.text);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Error de autenticación')));
      return;
    }

    final uid = auth.user?.uid;
    if (uid == null) return;
    await userProfileProvider.loadProfile(uid);
    if (!mounted) return;

    final nextRoute = userProfileProvider.hasCompletedOnboarding ? '/dashboard' : '/onboarding';
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Iniciar sesión' : 'Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'El email es obligatorio';
                final emailRegex = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$');
                if (!emailRegex.hasMatch(value.trim())) return 'Email inválido';
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
                if (value.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isLoginMode ? 'Entrar' : 'Crear cuenta'),
            ),
            TextButton(
              onPressed: auth.isLoading ? null : () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
            )
          ]),
        ),
      ),
    );
  }
}
