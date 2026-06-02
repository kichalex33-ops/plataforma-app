import 'package:flutter_test/flutter_test.dart';
import 'package:logisaude_driver/auth/motorista_model.dart';
import 'package:logisaude_driver/motorista/preparacao/models/viagem_preparacao_model.dart';
import 'package:logisaude_driver/motorista/preparacao/viagem_preparacao_service.dart';
import 'package:logisaude_driver/modules/sync/models/sync_metadata.dart';
import 'package:logisaude_driver/modules/transportes/models/viagem_model.dart';
import 'package:logisaude_driver/modules/transportes/models/viagem_status.dart';

void main() {
  late _FakePreparacaoStore store;
  late ViagemPreparacaoService service;
  late ViagemModel viagem;
  late MotoristaModel motorista;

  setUp(() {
    store = _FakePreparacaoStore();
    service = ViagemPreparacaoService(store: store);
    viagem = ViagemModel(
      sync: const SyncMetadata(
        id: 'viagem-1',
        municipioId: 'municipio-1',
        createdAt: '2026-06-02T08:00:00',
        updatedAt: '2026-06-02T08:00:00',
      ),
      motoristaId: 'motorista-1',
      veiculoId: 'veiculo-1',
      origem: 'Garagem municipal',
      destino: 'Hospital Regional',
      dataHoraSaida: '2026-06-02T09:00:00',
      status: ViagemStatus.agendada,
      statusOperacional: ViagemStatus.aguardando,
      prioridade: 'alta',
    );
    motorista = const MotoristaModel(
      id: 'motorista-1',
      nome: 'Alex',
      municipio: 'municipio-1',
    );
  });

  test('viagem carregada inicia em aguardando', () {
    expect(viagem.estadoOperacional, ViagemStatus.aguardando);
    expect(viagem.origem, 'Garagem municipal');
    expect(viagem.destinoExibicao, 'Hospital Regional');
  });

  test('preparacao criada altera estado para preparacao', () async {
    final preparacao = await service.iniciarPreparacao(
      viagem: viagem,
      motorista: motorista,
    );

    expect(preparacao.status, ViagemStatus.preparacao);
    expect(store.preparacoes, hasLength(1));
    expect(store.estados.last, ViagemStatus.preparacao);
    expect(store.eventos.last, 'preparacao_iniciada');
  });

  test('saida sem KM deve falhar', () async {
    final preparacao = await service.iniciarPreparacao(
      viagem: viagem,
      motorista: motorista,
    );

    expect(
      () => service.confirmarSaida(
        viagem: viagem,
        motorista: motorista,
        preparacao: preparacao,
        kmInicial: null,
        checklist: const {'Pneus': true},
      ),
      throwsA(isA<ViagemPreparacaoException>()),
    );
  });

  test('saida sem checklist deve falhar', () async {
    final preparacao = await service.iniciarPreparacao(
      viagem: viagem,
      motorista: motorista,
    );

    expect(
      () => service.confirmarSaida(
        viagem: viagem,
        motorista: motorista,
        preparacao: preparacao,
        kmInicial: 1234,
        checklist: const {'Pneus': true, 'Freios': false},
      ),
      throwsA(isA<ViagemPreparacaoException>()),
    );
  });

  test('saida valida deve funcionar', () async {
    final preparacao = await service.iniciarPreparacao(
      viagem: viagem,
      motorista: motorista,
    );

    final confirmada = await service.confirmarSaida(
      viagem: viagem,
      motorista: motorista,
      preparacao: preparacao,
      kmInicial: 1234,
      checklist: const {'Pneus': true, 'Freios': true},
    );

    expect(confirmada.status, ViagemStatus.saidaConfirmada);
    expect(confirmada.kmInicial, 1234);
    expect(confirmada.checklistConcluido, isTrue);
    expect(store.estados.last, ViagemStatus.saidaConfirmada);
    expect(store.statusLegados.last, ViagemStatus.emAndamento);
    expect(store.eventos.last, 'saida_confirmada');
  });

  test('mudanca de estado para em transito ida deve funcionar', () async {
    await service.iniciarTransitoIda(viagem: viagem, motorista: motorista);

    expect(store.estados.last, ViagemStatus.emTransitoIda);
    expect(store.statusLegados.last, ViagemStatus.emAndamento);
    expect(store.eventos.last, 'rota_ida_iniciada');
  });
}

class _FakePreparacaoStore implements ViagemPreparacaoStore {
  final List<ViagemPreparacaoModel> preparacoes = [];
  final List<String> estados = [];
  final List<String?> statusLegados = [];
  final List<String> eventos = [];

  @override
  Future<void> salvarPreparacao(ViagemPreparacaoModel preparacao) async {
    preparacoes.add(preparacao);
  }

  @override
  Future<void> atualizarEstadoViagem({
    required ViagemModel viagem,
    required String statusOperacional,
    String? statusLegado,
    double? kmSaida,
    String? horarioSaidaConfirmada,
  }) async {
    estados.add(statusOperacional);
    statusLegados.add(statusLegado);
  }

  @override
  Future<void> registrarEvento({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required String tipo,
    Map<String, dynamic> payload = const {},
  }) async {
    eventos.add(tipo);
  }
}
