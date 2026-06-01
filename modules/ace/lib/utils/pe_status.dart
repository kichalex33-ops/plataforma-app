import '../models/pe_model.dart';

class PEStatus {
  static const emDia = 'Em dia';
  static const vencendo = 'Vencendo';
  static const atrasado = 'Atrasado';

  static DateTime? converterData(String? dataTexto) {
    if (dataTexto == null || dataTexto.isEmpty) {
      return null;
    }

    try {
      final partes = dataTexto.split(' ');
      final data = partes[0].split('/');
      final hora = partes.length > 1 ? partes[1].split(':') : ['0', '0'];

      final dia = int.parse(data[0]);
      final mes = int.parse(data[1]);
      final ano = int.parse(data[2]);
      final horas = int.parse(hora[0]);
      final minutos = int.parse(hora[1]);

      return DateTime(ano, mes, dia, horas, minutos);
    } catch (_) {
      return null;
    }
  }

  static String calcular(PEModel pe, {DateTime? agora}) {
    final ultima = converterData(pe.ultimaVisita);

    if (ultima == null) {
      return atrasado;
    }

    final dias = (agora ?? DateTime.now()).difference(ultima).inDays;

    if (dias <= 10) {
      return emDia;
    }

    if (dias <= 15) {
      return vencendo;
    }

    return atrasado;
  }
}
