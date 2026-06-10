import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica_driver/models/trip_model.dart';
import 'package:plataforma_logistica_driver/motorista/home/motorista_home_page.dart';

void main() {
  test('Trip.fromJson interpreta dados da viagem ativa do servidor', () {
    final trip = Trip.fromJson({
      'id': 'v-001',
      'destino_nome': 'Hospital Municipal',
      'horario_previsto': '2026-06-10T09:30:00',
      'progresso': 0.35,
    }, now: DateTime(2026, 6, 10, 9));

    expect(trip.id, 'v-001');
    expect(trip.destination, 'Hospital Municipal');
    expect(trip.progress, 0.35);
    expect(trip.isLate, isFalse);
  });

  test('Trip marca atraso quando horario previsto ja passou', () {
    final trip = Trip.fromJson({
      'id': 'v-002',
      'destino_nome': 'Clinica Regional',
      'horario_previsto': '2026-06-10T08:00:00',
      'progresso': 0.5,
    }, now: DateTime(2026, 6, 10, 9));

    expect(trip.isLate, isTrue);
  });

  testWidgets('ActiveTripCard fica laranja e mostra atrasado', (tester) async {
    final trip = Trip(
      id: 'v-003',
      destination: 'UPA Centro',
      scheduledTime: DateTime(2026, 6, 10, 7),
      progress: 0.72,
      now: DateTime(2026, 6, 10, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ActiveTripCard(trip: trip)),
      ),
    );

    expect(find.text('UPA Centro'), findsOneWidget);
    expect(find.text('ATRASADO'), findsOneWidget);
    expect(find.text('72% concluido'), findsOneWidget);
    expect(find.text('Verifique o transito'), findsOneWidget);
  });
}
