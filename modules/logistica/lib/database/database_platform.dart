import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> configurarBancoPorPlataforma() async {
  if (kIsWeb) {
    // O painel web de Logística não deve depender de SQLite/worker no navegador.
    // Android/iOS continuam usando sqflite nativo e desktop usa FFI abaixo.
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
