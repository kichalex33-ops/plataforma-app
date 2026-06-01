import 'package:geolocator/geolocator.dart';

class GPSService {
  static Future<Position> obterLocalizacaoObrigatoria() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw Exception('Ative o GPS do aparelho para registrar a visita.');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied) {
      throw Exception(
        'Permita o acesso à localização para registrar a visita.',
      );
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'A permissão de localização foi bloqueada. Libere nas configurações do aparelho.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
