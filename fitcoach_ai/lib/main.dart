import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Intenta inicializar Firebase
    await Firebase.initializeApp();
    print("✅ FIREBASE CONECTADO EXITOSAMENTE");
  } catch (e) {
    print("❌ ERROR AL CONECTAR FIREBASE: $e");
  }

  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text("Prueba de Conexión")))));
}