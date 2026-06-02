import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'logistica_enums.dart';
import 'logistica_models.dart';

class LogisticaOfflineQueue {
  final Uuid uuid;

  const LogisticaOfflineQueue({this.uuid = const Uuid()});

  LogisticaSyncItem criarItem({
    required TipoEventoSync tipoEvento,
    required Map<String, dynamic> payload,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return LogisticaSyncItem(
      idLocal: uuid.v4(),
      createdAt: timestamp,
      updatedAt: timestamp,
      statusSync: StatusSync.pendente,
      tipoEvento: tipoEvento,
      payloadJson: jsonEncode(payload),
    );
  }

  LogisticaSyncItem marcarTentativa(
    LogisticaSyncItem item, {
    DateTime? now,
    String? erro,
  }) {
    final timestamp = now ?? DateTime.now();
    return LogisticaSyncItem(
      idLocal: item.idLocal,
      idServidor: item.idServidor,
      createdAt: item.createdAt,
      updatedAt: timestamp,
      statusSync: erro == null ? StatusSync.enviando : StatusSync.erro,
      tipoEvento: item.tipoEvento,
      payloadJson: item.payloadJson,
      tentativas: item.tentativas + 1,
      ultimaTentativa: timestamp,
      erro: erro,
    );
  }
}
