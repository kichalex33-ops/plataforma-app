import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/rg_quarteiroes_seed.dart';
import '../models/ace_profile_model.dart';
import '../models/alerta_emergencia_model.dart';
import '../models/atividade_quarteirao_model.dart';
import '../models/area_prioritaria_model.dart';
import '../models/bti_model.dart';
import '../models/bti_point_model.dart';
import '../models/exclusao_log_model.dart';
import '../models/lira_lia_visita_model.dart';
import '../models/ovitrampa_check_model.dart';
import '../models/ovitrampa_model.dart';
import '../models/pe_model.dart';
import '../models/quarteirao_model.dart';
import '../models/rg_quarteirao_model.dart';
import '../models/relatorio_pe_item_model.dart';
import '../models/visita_domiciliar_model.dart';
import '../models/visita_pe_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('controle_ace.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await openDatabase(
        filePath,
        version: 22,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 22,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pontos_estrategicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        endereco TEXT NOT NULL,
        tipo TEXT NOT NULL,
        status TEXT NOT NULL,
        ultima_visita TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE visitas_pe (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pe_id INTEGER NOT NULL,
        data_visita TEXT NOT NULL,
        entrada_em TEXT,
        saida_em TEXT,
        municipio TEXT,
        agente TEXT,
        situacao TEXT NOT NULL,
        foco_positivo INTEGER NOT NULL DEFAULT 0,
        quantidade_tubitos INTEGER NOT NULL DEFAULT 0,
        observacoes TEXT,
        foto_path TEXT,
        latitude REAL,
        longitude REAL,
        entrada_latitude REAL,
        entrada_longitude REAL,
        saida_latitude REAL,
        saida_longitude REAL,
        FOREIGN KEY (pe_id) REFERENCES pontos_estrategicos (id)
      )
    ''');

    await _createConfigTable(db);
    await _createACEProfilesTable(db);
    await _createTubitosTable(db);
    await _createVisitasDomiciliaresTable(db);
    await _createTubitosDomiciliaresTable(db);
    await _createBTITable(db);
    await _createBTIPointsTable(db);
    await _createOvitrampasTables(db);
    await _createAreasPrioritariasTable(db);
    await _createRGQuarteiroesTable(db);
    await _seedRGQuarteiroes(db);
    await _createLiraLiaTable(db);
    await _createQuarteiroesTables(db);
    await _createExclusoesLogTable(db);
    await _createAlertasEmergenciaTable(db);
    await _createSyncQueueTable(db);
    await _createTerritorioOperacionalTables(db);
    await _createAuditoriaEventosTable(db);
    await _createPlataformaMunicipalTables(db);
    await _createRastreamentoViagemTable(db);
    await _createSyncColumns(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS visitas_pe (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pe_id INTEGER NOT NULL,
          data_visita TEXT NOT NULL,
          entrada_em TEXT,
          saida_em TEXT,
          municipio TEXT,
          agente TEXT,
          situacao TEXT NOT NULL,
          foco_positivo INTEGER NOT NULL DEFAULT 0,
          quantidade_tubitos INTEGER NOT NULL DEFAULT 0,
          observacoes TEXT,
          foto_path TEXT,
          FOREIGN KEY (pe_id) REFERENCES pontos_estrategicos (id)
        )
      ''');
    }

    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'visitas_pe', 'entrada_em', 'TEXT');
      await _addColumnIfMissing(db, 'visitas_pe', 'saida_em', 'TEXT');
      await _addColumnIfMissing(db, 'visitas_pe', 'municipio', 'TEXT');
      await _addColumnIfMissing(db, 'visitas_pe', 'agente', 'TEXT');
      await _addColumnIfMissing(db, 'visitas_pe', 'foto_path', 'TEXT');
      await _createConfigTable(db);
    }

    if (oldVersion < 4) {
      await _addColumnIfMissing(
        db,
        'visitas_pe',
        'foco_positivo',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'visitas_pe',
        'quantidade_tubitos',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _createTubitosTable(db);
    }

    if (oldVersion < 5) {
      await _createACEProfilesTable(db);
    }

    if (oldVersion < 6) {
      await _addColumnIfMissing(db, 'pontos_estrategicos', 'latitude', 'REAL');
      await _addColumnIfMissing(db, 'pontos_estrategicos', 'longitude', 'REAL');
      await _addColumnIfMissing(db, 'visitas_pe', 'latitude', 'REAL');
      await _addColumnIfMissing(db, 'visitas_pe', 'longitude', 'REAL');
    }

    if (oldVersion < 7) {
      await _addColumnIfMissing(db, 'visitas_pe', 'entrada_latitude', 'REAL');
      await _addColumnIfMissing(db, 'visitas_pe', 'entrada_longitude', 'REAL');
      await _addColumnIfMissing(db, 'visitas_pe', 'saida_latitude', 'REAL');
      await _addColumnIfMissing(db, 'visitas_pe', 'saida_longitude', 'REAL');
      await _createVisitasDomiciliaresTable(db);
      await _createTubitosDomiciliaresTable(db);
    }

    if (oldVersion < 8) {
      await _createBTITable(db);
    }

    if (oldVersion < 9) {
      await _addColumnIfMissing(
        db,
        'bti_aplicacoes',
        'ponto_bti_id',
        'INTEGER',
      );
      await _createBTIPointsTable(db);
    }

    if (oldVersion < 10) {
      await _createBTIPointsTable(db);
    }

    if (oldVersion < 11) {
      await _createOvitrampasTables(db);
    }

    if (oldVersion < 12) {
      await _createSyncColumns(db);
    }

    if (oldVersion < 13) {
      await _createAreasPrioritariasTable(db);
      await _createSyncColumns(db);
    }

    if (oldVersion < 14) {
      await _addColumnIfMissing(
        db,
        'visitas_domiciliares',
        'rg_quarteirao_id',
        'INTEGER',
      );
      await _addColumnIfMissing(
        db,
        'visitas_domiciliares',
        'rg_quarteirao_codigo',
        'TEXT',
      );
      await _createRGQuarteiroesTable(db);
      await _seedRGQuarteiroes(db);
    }

    if (oldVersion < 15) {
      await _createLiraLiaTable(db);
      await _createSyncColumns(db);
    }

    if (oldVersion < 16) {
      await _createQuarteiroesTables(db);
      await _createSyncColumns(db);
    }

    if (oldVersion < 17) {
      await _createExclusoesLogTable(db);
      await _createSyncColumns(db);
    }

    if (oldVersion < 18) {
      await _createAlertasEmergenciaTable(db);
      await _createSyncColumns(db);
    }

    if (oldVersion < 19) {
      await _createBTIPointsTable(db);
      await db.delete('bti_pontos');
      await _createSyncColumns(db);
    }

    if (oldVersion < 20) {
      await _createSyncQueueTable(db);
      await _createTerritorioOperacionalTables(db);
      await _createAuditoriaEventosTable(db);
      await _createSyncColumns(db);
    }

    if (oldVersion < 21) {
      await _createPlataformaMunicipalTables(db);
    }

    if (oldVersion < 22) {
      await _createRastreamentoViagemTable(db);
    }
  }

  Future<void> _createSyncColumns(Database db) async {
    const tabelas = [
      'pontos_estrategicos',
      'visitas_pe',
      'visitas_domiciliares',
      'bti_aplicacoes',
      'bti_pontos',
      'ovitrampas',
      'ovitrampa_checagens',
      'areas_prioritarias',
      'lira_lia_visitas',
      'quarteiroes',
      'atividades_quarteirao',
      'exclusoes_log',
      'alertas_emergencia',
      'localidades',
      'setores_operacionais',
      'quarteiroes_operacionais',
      'atribuicoes_setor',
      'progresso_quarteirao',
      'auditoria_eventos',
    ];

    for (final tabela in tabelas) {
      if (!await _tableExists(db, tabela)) {
        continue;
      }

      await _addColumnIfMissing(
        db,
        tabela,
        'sincronizado',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(db, tabela, 'sincronizado_em', 'TEXT');
      await _addColumnIfMissing(db, tabela, 'erro_sincronizacao', 'TEXT');
    }
  }

  Future<bool> _tableExists(Database db, String table) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );

    return result.isNotEmpty;
  }

  Future<void> _createConfigTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_config (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createExclusoesLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exclusoes_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entidade TEXT NOT NULL,
        entidade_id INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        justificativa TEXT NOT NULL,
        agente TEXT,
        municipio TEXT,
        data_hora TEXT NOT NULL,
        origem TEXT NOT NULL DEFAULT 'app_flutter'
      )
    ''');
  }

  Future<void> _createAlertasEmergenciaTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alertas_emergencia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agente TEXT,
        municipio TEXT,
        data_hora TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        status TEXT NOT NULL DEFAULT 'Registrado'
      )
    ''');
  }

  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        checksum TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_attempt_at TEXT,
        error_message TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)',
    );
  }

  Future<void> _createAuditoriaEventosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auditoria_eventos (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        actor_id TEXT,
        descricao TEXT NOT NULL,
        justificativa TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }

  Future<void> _createTerritorioOperacionalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS localidades (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        observacoes TEXT,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS setores_operacionais (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        localidade_id TEXT NOT NULL,
        codigo TEXT NOT NULL,
        nome TEXT NOT NULL,
        descricao TEXT,
        supervisor_id TEXT,
        status TEXT NOT NULL,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (localidade_id) REFERENCES localidades (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS quarteiroes_operacionais (
        id TEXT PRIMARY KEY,
        setor_id TEXT NOT NULL,
        municipio_id TEXT NOT NULL,
        localidade_id TEXT NOT NULL,
        codigo TEXT NOT NULL,
        ordem_execucao INTEGER NOT NULL,
        status TEXT NOT NULL,
        total_imoveis_previstos INTEGER NOT NULL DEFAULT 0,
        total_visitados INTEGER NOT NULL DEFAULT 0,
        total_fechados INTEGER NOT NULL DEFAULT 0,
        total_recusas INTEGER NOT NULL DEFAULT 0,
        total_focos INTEGER NOT NULL DEFAULT 0,
        total_pendencias INTEGER NOT NULL DEFAULT 0,
        geometria_geojson TEXT,
        centro_latitude REAL,
        centro_longitude REAL,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (setor_id) REFERENCES setores_operacionais (id),
        FOREIGN KEY (localidade_id) REFERENCES localidades (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS atribuicoes_setor (
        id TEXT PRIMARY KEY,
        setor_id TEXT NOT NULL,
        ace_id TEXT NOT NULL,
        supervisor_id TEXT,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT NOT NULL,
        observacoes TEXT,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (setor_id) REFERENCES setores_operacionais (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS progresso_quarteirao (
        id TEXT PRIMARY KEY,
        quarteirao_id TEXT NOT NULL,
        ace_id TEXT NOT NULL,
        status TEXT NOT NULL,
        iniciado_em TEXT,
        concluido_em TEXT,
        total_visitados INTEGER NOT NULL DEFAULT 0,
        total_pendencias INTEGER NOT NULL DEFAULT 0,
        observacoes TEXT,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (quarteirao_id) REFERENCES quarteiroes_operacionais (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_setores_localidade ON setores_operacionais(localidade_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quarteiroes_setor_ordem ON quarteiroes_operacionais(setor_id, ordem_execucao)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_atribuicoes_ace ON atribuicoes_setor(ace_id, status)',
    );
  }

  Future<void> _createPlataformaMunicipalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transportes_motoristas (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        cpf TEXT,
        telefone TEXT,
        cnh TEXT,
        status TEXT NOT NULL DEFAULT 'ativo',
        observacoes TEXT,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transportes_veiculos (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        placa TEXT NOT NULL,
        modelo TEXT NOT NULL,
        tipo TEXT NOT NULL,
        capacidade INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ativo',
        observacoes TEXT,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transportes_viagens (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        motorista_id TEXT,
        veiculo_id TEXT,
        origem TEXT NOT NULL,
        destino TEXT NOT NULL,
        data_hora_saida TEXT NOT NULL,
        data_hora_retorno TEXT,
        status TEXT NOT NULL DEFAULT 'rascunho',
        finalidade TEXT,
        rota_geojson TEXT,
        observacoes TEXT,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (motorista_id) REFERENCES transportes_motoristas (id),
        FOREIGN KEY (veiculo_id) REFERENCES transportes_veiculos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transportes_passageiros (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        viagem_id TEXT NOT NULL,
        paciente_id TEXT,
        nome TEXT NOT NULL,
        documento TEXT,
        necessidade_especial TEXT,
        embarque TEXT,
        desembarque TEXT,
        status TEXT NOT NULL DEFAULT 'agendado',
        observacoes TEXT,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (viagem_id) REFERENCES transportes_viagens (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pacientes (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        cpf TEXT,
        cns TEXT,
        data_nascimento TEXT,
        telefone TEXT,
        endereco TEXT,
        bairro TEXT,
        referencia TEXT,
        latitude REAL,
        longitude REAL,
        necessidades_especiais TEXT,
        observacoes TEXT,
        status TEXT NOT NULL DEFAULT 'ativo',
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mapas_camadas (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        ativa INTEGER NOT NULL DEFAULT 1,
        configuracao_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_logs (
        id TEXT PRIMARY KEY,
        entity_type TEXT,
        entity_id TEXT,
        status TEXT NOT NULL,
        message TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_viagens_status ON transportes_viagens(municipio_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_passageiros_viagem ON transportes_passageiros(viagem_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pacientes_municipio ON pacientes(municipio_id, nome)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_logs_created ON sync_logs(created_at)',
    );
  }

  Future<void> _createRastreamentoViagemTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rastreamento_viagem (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        viagem_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        velocidade REAL,
        timestamp TEXT NOT NULL,
        origem_dado TEXT NOT NULL,
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (viagem_id) REFERENCES transportes_viagens (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rastreamento_viagem_timestamp ON rastreamento_viagem(viagem_id, timestamp)',
    );
  }

  Future<void> _createACEProfilesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ace_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        municipio TEXT NOT NULL,
        senha TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTubitosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tubitos_coleta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visita_pe_id INTEGER NOT NULL,
        numero INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (visita_pe_id) REFERENCES visitas_pe (id)
      )
    ''');
  }

  Future<void> _createVisitasDomiciliaresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitas_domiciliares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rg_quarteirao_id INTEGER,
        rg_quarteirao_codigo TEXT,
        endereco TEXT NOT NULL,
        numero TEXT,
        complemento TEXT,
        municipio TEXT,
        agente TEXT,
        entrada_em TEXT NOT NULL,
        saida_em TEXT NOT NULL,
        situacao TEXT NOT NULL,
        foco_positivo INTEGER NOT NULL DEFAULT 0,
        quantidade_tubitos INTEGER NOT NULL DEFAULT 0,
        observacoes TEXT,
        entrada_latitude REAL NOT NULL,
        entrada_longitude REAL NOT NULL,
        saida_latitude REAL NOT NULL,
        saida_longitude REAL NOT NULL
      )
    ''');
  }

  Future<void> _createTubitosDomiciliaresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tubitos_domiciliares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visita_domiciliar_id INTEGER NOT NULL,
        numero INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (visita_domiciliar_id) REFERENCES visitas_domiciliares (id)
      )
    ''');
  }

  Future<void> _createBTITable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bti_aplicacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ponto_bti_id INTEGER,
        local TEXT NOT NULL,
        tipo_criadouro TEXT NOT NULL,
        municipio TEXT,
        agente TEXT,
        data_aplicacao TEXT NOT NULL,
        volume_litros REAL NOT NULL,
        dosagem_gramas REAL NOT NULL,
        periodicidade TEXT NOT NULL,
        observacoes TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  Future<void> _createBTIPointsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bti_pontos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  Future<void> _createOvitrampasTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ovitrampas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL,
        endereco TEXT NOT NULL,
        referencia TEXT,
        municipio TEXT,
        agente_instalacao TEXT,
        instalada_em TEXT NOT NULL,
        status TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        ultima_checagem TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ovitrampa_checagens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ovitrampa_id INTEGER NOT NULL,
        data_checagem TEXT NOT NULL,
        agente TEXT,
        resultado TEXT NOT NULL,
        quantidade_ovos INTEGER NOT NULL DEFAULT 0,
        observacoes TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        FOREIGN KEY (ovitrampa_id) REFERENCES ovitrampas (id)
      )
    ''');
  }

  Future<void> _createAreasPrioritariasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS areas_prioritarias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        endereco TEXT NOT NULL,
        tipo_risco TEXT NOT NULL,
        grau_risco TEXT NOT NULL,
        motivo_prioridade TEXT NOT NULL,
        municipio TEXT,
        agente TEXT,
        data_registro TEXT NOT NULL,
        status TEXT NOT NULL,
        observacoes TEXT,
        gravidade INTEGER NOT NULL DEFAULT 1,
        urgencia INTEGER NOT NULL DEFAULT 1,
        tendencia INTEGER NOT NULL DEFAULT 1,
        prioridade_gut INTEGER NOT NULL DEFAULT 1,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  Future<void> _createRGQuarteiroesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rg_quarteiroes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL,
        ordem INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  Future<void> _createLiraLiaTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lira_lia_visitas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rg_quarteirao_id INTEGER,
        rg_quarteirao_codigo TEXT,
        tipo_levantamento TEXT NOT NULL,
        municipio TEXT,
        agente TEXT,
        data_registro TEXT NOT NULL,
        imoveis_previstos INTEGER NOT NULL DEFAULT 0,
        imoveis_trabalhados INTEGER NOT NULL DEFAULT 0,
        imoveis_fechados INTEGER NOT NULL DEFAULT 0,
        focos_positivos INTEGER NOT NULL DEFAULT 0,
        observacoes TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  Future<void> _createQuarteiroesTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quarteiroes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL,
        localidade TEXT NOT NULL,
        total_imoveis INTEGER NOT NULL DEFAULT 0,
        residencias INTEGER NOT NULL DEFAULT 0,
        comercios INTEGER NOT NULL DEFAULT 0,
        pontos_estrategicos INTEGER NOT NULL DEFAULT 0,
        outros INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        ultima_data_trabalhada TEXT,
        atividade_atual TEXT NOT NULL,
        latitude REAL,
        longitude REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS atividades_quarteirao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quarteirao_id INTEGER NOT NULL,
        quarteirao_numero TEXT NOT NULL,
        localidade TEXT NOT NULL,
        data_atividade TEXT NOT NULL,
        agente TEXT,
        atividade TEXT NOT NULL,
        imoveis_previstos INTEGER NOT NULL DEFAULT 0,
        imoveis_visitados INTEGER NOT NULL DEFAULT 0,
        imoveis_fechados INTEGER NOT NULL DEFAULT 0,
        imoveis_recusados INTEGER NOT NULL DEFAULT 0,
        imoveis_pendentes INTEGER NOT NULL DEFAULT 0,
        coletas_realizadas INTEGER NOT NULL DEFAULT 0,
        coletas_positivas INTEGER NOT NULL DEFAULT 0,
        coletas_negativas INTEGER NOT NULL DEFAULT 0,
        observacoes TEXT,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (quarteirao_id) REFERENCES quarteiroes (id)
      )
    ''');
  }

  Future<void> _seedRGQuarteiroes(Database db) async {
    for (final quarteirao in rgQuarteiroesSeed) {
      final ordem = quarteirao['ordem'] as int;
      final existe = await db.query(
        'rg_quarteiroes',
        where: 'ordem = ?',
        whereArgs: [ordem],
        limit: 1,
      );

      if (existe.isNotEmpty) continue;

      await db.insert('rg_quarteiroes', quarteirao);
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);

    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<int> inserirPE(PEModel pe) async {
    final db = await instance.database;

    return await db.insert('pontos_estrategicos', pe.toMap());
  }

  Future<List<PEModel>> listarPEs() async {
    final db = await instance.database;

    final result = await db.query('pontos_estrategicos', orderBy: 'id DESC');

    return result.map((map) => PEModel.fromMap(map)).toList();
  }

  Future<int> excluirPE(int id) async {
    final db = await instance.database;

    await db.rawDelete(
      '''
      DELETE FROM tubitos_coleta
      WHERE visita_pe_id IN (
        SELECT id FROM visitas_pe WHERE pe_id = ?
      )
      ''',
      [id],
    );

    await db.delete('visitas_pe', where: 'pe_id = ?', whereArgs: [id]);

    return await db.delete(
      'pontos_estrategicos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> excluirPEComJustificativa({
    required PEModel pe,
    required String justificativa,
    required String agente,
    required String municipio,
  }) async {
    final db = await instance.database;
    final id = pe.id;

    if (id == null) return 0;

    return await db.transaction((txn) async {
      await txn.insert(
        'exclusoes_log',
        ExclusaoLogModel(
          entidade: 'PE',
          entidadeId: id,
          descricao: '${pe.nome} - ${pe.endereco}',
          justificativa: justificativa,
          agente: agente,
          municipio: municipio,
          dataHora: DateTime.now().toIso8601String(),
        ).toMap()..remove('id'),
      );

      await txn.rawDelete(
        '''
        DELETE FROM tubitos_coleta
        WHERE visita_pe_id IN (
          SELECT id FROM visitas_pe WHERE pe_id = ?
        )
        ''',
        [id],
      );

      await txn.delete('visitas_pe', where: 'pe_id = ?', whereArgs: [id]);

      return await txn.delete(
        'pontos_estrategicos',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<int> inserirExclusaoLog(ExclusaoLogModel log) async {
    final db = await instance.database;
    return await db.insert('exclusoes_log', log.toMap()..remove('id'));
  }

  Future<List<ExclusaoLogModel>> listarExclusoesLog() async {
    final db = await instance.database;
    final result = await db.query('exclusoes_log', orderBy: 'id DESC');
    return result.map((map) => ExclusaoLogModel.fromMap(map)).toList();
  }

  Future<int> inserirAlertaEmergencia(AlertaEmergenciaModel alerta) async {
    final db = await instance.database;
    return await db.insert('alertas_emergencia', alerta.toMap()..remove('id'));
  }

  Future<List<AlertaEmergenciaModel>> listarAlertasEmergencia() async {
    final db = await instance.database;
    final result = await db.query('alertas_emergencia', orderBy: 'id DESC');
    return result.map((map) => AlertaEmergenciaModel.fromMap(map)).toList();
  }

  Future<int> inserirVisitaPE({
    required int peId,
    required String dataVisita,
    required String entradaEm,
    required String saidaEm,
    required String municipio,
    required String agente,
    required String situacao,
    required bool focoPositivo,
    required int quantidadeTubitos,
    required String observacoes,
    required String fotoPath,
    double? latitude,
    double? longitude,
    double? entradaLatitude,
    double? entradaLongitude,
    double? saidaLatitude,
    double? saidaLongitude,
    int? tubitoInicial,
  }) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final visitaId = await txn.insert('visitas_pe', {
        'pe_id': peId,
        'data_visita': dataVisita,
        'entrada_em': entradaEm,
        'saida_em': saidaEm,
        'municipio': municipio,
        'agente': agente,
        'situacao': situacao,
        'foco_positivo': focoPositivo ? 1 : 0,
        'quantidade_tubitos': focoPositivo ? quantidadeTubitos : 0,
        'observacoes': observacoes,
        'foto_path': fotoPath,
        'latitude': latitude,
        'longitude': longitude,
        'entrada_latitude': entradaLatitude,
        'entrada_longitude': entradaLongitude,
        'saida_latitude': saidaLatitude,
        'saida_longitude': saidaLongitude,
      });

      if (focoPositivo) {
        final ultimoTubito = await _buscarUltimoNumeroTubitoTxn(txn);
        final primeiroTubito = tubitoInicial ?? ultimoTubito + 1;

        for (var index = 1; index <= quantidadeTubitos; index++) {
          await txn.insert('tubitos_coleta', {
            'visita_pe_id': visitaId,
            'numero': primeiroTubito + index - 1,
            'created_at': dataVisita,
          });
        }
      }

      await txn.update(
        'pontos_estrategicos',
        {'ultima_visita': dataVisita},
        where: 'id = ?',
        whereArgs: [peId],
      );

      return visitaId;
    });
  }

  Future<List<VisitaPEModel>> listarVisitasPE(int peId) async {
    final db = await instance.database;

    final result = await db.query(
      'visitas_pe',
      where: 'pe_id = ?',
      whereArgs: [peId],
      orderBy: 'id DESC',
    );

    final visitas = <VisitaPEModel>[];

    for (final map in result) {
      final visitaId = map['id'] as int;
      final tubitos = await listarTubitosVisitaPE(visitaId);

      visitas.add(VisitaPEModel.fromMap(map, tubitos: tubitos));
    }

    return visitas;
  }

  Future<List<int>> listarTubitosVisitaPE(int visitaId) async {
    final db = await instance.database;

    final result = await db.query(
      'tubitos_coleta',
      where: 'visita_pe_id = ?',
      whereArgs: [visitaId],
      orderBy: 'numero ASC',
    );

    return result.map((map) => map['numero'] as int).toList();
  }

  Future<List<RelatorioPEItemModel>> listarRelatorioPE() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT
        v.*,
        pe.nome AS pe_nome,
        pe.endereco AS pe_endereco,
        pe.tipo AS pe_tipo
      FROM visitas_pe v
      INNER JOIN pontos_estrategicos pe ON pe.id = v.pe_id
      ORDER BY v.id DESC
    ''');

    final itens = <RelatorioPEItemModel>[];

    for (final map in result) {
      final visitaId = map['id'] as int;
      final tubitos = await listarTubitosVisitaPE(visitaId);
      final visita = VisitaPEModel.fromMap(map, tubitos: tubitos);

      itens.add(
        RelatorioPEItemModel(
          peNome: map['pe_nome']?.toString() ?? '',
          peEndereco: map['pe_endereco']?.toString() ?? '',
          peTipo: map['pe_tipo']?.toString() ?? '',
          visita: visita,
        ),
      );
    }

    return itens;
  }

  Future<int> buscarUltimoNumeroTubito() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT MAX(numero) AS ultimo
      FROM (
        SELECT numero FROM tubitos_coleta
        UNION ALL
        SELECT numero FROM tubitos_domiciliares
      )
      ''');

    return result.first['ultimo'] as int? ?? 0;
  }

  Future<int> inserirVisitaDomiciliar({
    int? rgQuarteiraoId,
    String? rgQuarteiraoCodigo,
    required String endereco,
    required String numero,
    required String complemento,
    required String municipio,
    required String agente,
    required String entradaEm,
    required String saidaEm,
    required String situacao,
    required bool focoPositivo,
    required int quantidadeTubitos,
    required String observacoes,
    required double entradaLatitude,
    required double entradaLongitude,
    required double saidaLatitude,
    required double saidaLongitude,
    int? tubitoInicial,
  }) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final visitaId = await txn.insert('visitas_domiciliares', {
        'rg_quarteirao_id': rgQuarteiraoId,
        'rg_quarteirao_codigo': rgQuarteiraoCodigo,
        'endereco': endereco,
        'numero': numero,
        'complemento': complemento,
        'municipio': municipio,
        'agente': agente,
        'entrada_em': entradaEm,
        'saida_em': saidaEm,
        'situacao': situacao,
        'foco_positivo': focoPositivo ? 1 : 0,
        'quantidade_tubitos': focoPositivo ? quantidadeTubitos : 0,
        'observacoes': observacoes,
        'entrada_latitude': entradaLatitude,
        'entrada_longitude': entradaLongitude,
        'saida_latitude': saidaLatitude,
        'saida_longitude': saidaLongitude,
      });

      if (focoPositivo) {
        final ultimoTubito = await _buscarUltimoNumeroTubitoTxn(txn);
        final primeiroTubito = tubitoInicial ?? ultimoTubito + 1;

        for (var index = 1; index <= quantidadeTubitos; index++) {
          await txn.insert('tubitos_domiciliares', {
            'visita_domiciliar_id': visitaId,
            'numero': primeiroTubito + index - 1,
            'created_at': saidaEm,
          });
        }
      }

      return visitaId;
    });
  }

  Future<int> _buscarUltimoNumeroTubitoTxn(Transaction txn) async {
    final result = await txn.rawQuery('''
      SELECT MAX(numero) AS ultimo
      FROM (
        SELECT numero FROM tubitos_coleta
        UNION ALL
        SELECT numero FROM tubitos_domiciliares
      )
    ''');

    return result.first['ultimo'] as int? ?? 0;
  }

  Future<List<int>> listarTubitosVisitaDomiciliar(int visitaId) async {
    final db = await instance.database;
    final result = await db.query(
      'tubitos_domiciliares',
      where: 'visita_domiciliar_id = ?',
      whereArgs: [visitaId],
      orderBy: 'numero ASC',
    );

    return result.map((map) => map['numero'] as int).toList();
  }

  Future<List<VisitaDomiciliarModel>> listarVisitasDomiciliares() async {
    final db = await instance.database;
    final result = await db.query('visitas_domiciliares', orderBy: 'id DESC');

    final visitas = <VisitaDomiciliarModel>[];

    for (final map in result) {
      final visitaId = map['id'] as int;
      final tubitos = await listarTubitosVisitaDomiciliar(visitaId);
      visitas.add(VisitaDomiciliarModel.fromMap(map, tubitos: tubitos));
    }

    return visitas;
  }

  Future<int> inserirBTI(BTIModel bti) async {
    final db = await instance.database;
    return await db.insert('bti_aplicacoes', bti.toMap());
  }

  Future<List<BTIModel>> listarBTI() async {
    final db = await instance.database;
    final result = await db.query('bti_aplicacoes', orderBy: 'id DESC');
    return result.map((map) => BTIModel.fromMap(map)).toList();
  }

  Future<List<BTIPointModel>> listarPontosBTI() async {
    final db = await instance.database;
    final result = await db.query('bti_pontos', orderBy: 'nome ASC');
    return result.map((map) => BTIPointModel.fromMap(map)).toList();
  }

  Future<int> inserirPontoBTI(BTIPointModel ponto) async {
    final db = await instance.database;
    return await db.insert('bti_pontos', ponto.toMap()..remove('id'));
  }

  Future<int> excluirPontoBTI(int id) async {
    final db = await instance.database;
    return await db.delete('bti_pontos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> inserirOvitrampa(OvitrampaModel ovitrampa) async {
    final db = await instance.database;
    return await db.insert('ovitrampas', ovitrampa.toMap());
  }

  Future<List<OvitrampaModel>> listarOvitrampas() async {
    final db = await instance.database;
    final result = await db.query('ovitrampas', orderBy: 'id DESC');
    return result.map((map) => OvitrampaModel.fromMap(map)).toList();
  }

  Future<int> excluirOvitrampa(int id) async {
    final db = await instance.database;
    await db.delete(
      'ovitrampa_checagens',
      where: 'ovitrampa_id = ?',
      whereArgs: [id],
    );
    return await db.delete('ovitrampas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> inserirChecagemOvitrampa({
    required int ovitrampaId,
    required String dataChecagem,
    required String agente,
    required String resultado,
    required int quantidadeOvos,
    required String observacoes,
    required double latitude,
    required double longitude,
  }) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final id = await txn.insert('ovitrampa_checagens', {
        'ovitrampa_id': ovitrampaId,
        'data_checagem': dataChecagem,
        'agente': agente,
        'resultado': resultado,
        'quantidade_ovos': quantidadeOvos,
        'observacoes': observacoes,
        'latitude': latitude,
        'longitude': longitude,
      });

      await txn.update(
        'ovitrampas',
        {'ultima_checagem': dataChecagem, 'status': resultado},
        where: 'id = ?',
        whereArgs: [ovitrampaId],
      );

      return id;
    });
  }

  Future<List<OvitrampaCheckModel>> listarChecagensOvitrampa(
    int ovitrampaId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'ovitrampa_checagens',
      where: 'ovitrampa_id = ?',
      whereArgs: [ovitrampaId],
      orderBy: 'id DESC',
    );
    return result.map((map) => OvitrampaCheckModel.fromMap(map)).toList();
  }

  Future<int> inserirAreaPrioritaria(AreaPrioritariaModel area) async {
    final db = await instance.database;
    return await db.insert('areas_prioritarias', area.toMap());
  }

  Future<List<AreaPrioritariaModel>> listarAreasPrioritarias() async {
    final db = await instance.database;
    final result = await db.query(
      'areas_prioritarias',
      orderBy: 'prioridade_gut DESC, id DESC',
    );
    return result.map((map) => AreaPrioritariaModel.fromMap(map)).toList();
  }

  Future<List<RGQuarteiraoModel>> listarRGQuarteiroes() async {
    final db = await instance.database;
    final result = await db.query('rg_quarteiroes', orderBy: 'ordem ASC');
    return result.map((map) => RGQuarteiraoModel.fromMap(map)).toList();
  }

  Future<int> inserirLiraLiaVisita(LiraLiaVisitaModel visita) async {
    final db = await instance.database;
    return await db.insert('lira_lia_visitas', visita.toMap());
  }

  Future<List<LiraLiaVisitaModel>> listarLiraLiaVisitas() async {
    final db = await instance.database;
    final result = await db.query('lira_lia_visitas', orderBy: 'id DESC');
    return result.map((map) => LiraLiaVisitaModel.fromMap(map)).toList();
  }

  Future<int> inserirQuarteirao(QuarteiraoModel quarteirao) async {
    final db = await instance.database;
    return await db.insert('quarteiroes', quarteirao.toMap());
  }

  Future<List<QuarteiraoModel>> listarQuarteiroes() async {
    final db = await instance.database;
    final result = await db.query(
      'quarteiroes',
      orderBy: 'localidade ASC, numero ASC',
    );
    return result.map((map) => QuarteiraoModel.fromMap(map)).toList();
  }

  Future<int> inserirAtividadeQuarteirao(
    AtividadeQuarteiraoModel atividade,
  ) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final id = await txn.insert('atividades_quarteirao', atividade.toMap());

      await txn.update(
        'quarteiroes',
        {
          'ultima_data_trabalhada': atividade.dataAtividade,
          'atividade_atual': atividade.atividade,
          'status': atividade.imoveisPendentes > 0
              ? 'Em andamento'
              : 'Concluido',
        },
        where: 'id = ?',
        whereArgs: [atividade.quarteiraoId],
      );

      return id;
    });
  }

  Future<List<AtividadeQuarteiraoModel>> listarAtividadesQuarteirao({
    int? quarteiraoId,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'atividades_quarteirao',
      where: quarteiraoId == null ? null : 'quarteirao_id = ?',
      whereArgs: quarteiraoId == null ? null : [quarteiraoId],
      orderBy: 'id DESC',
    );
    return result.map((map) => AtividadeQuarteiraoModel.fromMap(map)).toList();
  }

  Future<int> excluirAreaPrioritaria(int id) async {
    final db = await instance.database;
    return await db.delete(
      'areas_prioritarias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> contarPendentesSincronizacao() async {
    final db = await instance.database;
    const tabelas = [
      'pontos_estrategicos',
      'visitas_pe',
      'visitas_domiciliares',
      'bti_aplicacoes',
      'ovitrampas',
      'ovitrampa_checagens',
      'areas_prioritarias',
      'lira_lia_visitas',
      'quarteiroes',
      'atividades_quarteirao',
      'exclusoes_log',
      'alertas_emergencia',
    ];

    var total = 0;
    for (final tabela in tabelas) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM $tabela WHERE sincronizado = 0',
      );
      total += result.first['total'] as int? ?? 0;
    }

    final fila = await db.rawQuery('''
      SELECT COUNT(*) AS total FROM sync_queue
      WHERE status IN ('pending', 'failed', 'processing')
    ''');
    total += fila.first['total'] as int? ?? 0;

    return total;
  }

  Future<List<Map<String, dynamic>>> listarResumoSincronizacao() async {
    final db = await instance.database;
    const tabelas = {
      'pontos_estrategicos': 'Pontos Estrategicos',
      'visitas_pe': 'Visitas PE',
      'visitas_domiciliares': 'Visitas domiciliares',
      'bti_aplicacoes': 'BTI',
      'bti_pontos': 'Pontos BTI',
      'ovitrampas': 'Ovitrampas',
      'ovitrampa_checagens': 'Checagens de ovitrampas',
      'areas_prioritarias': 'Areas prioritarias',
      'lira_lia_visitas': 'LIRA/LIA',
      'quarteiroes': 'Quarteiroes',
      'atividades_quarteirao': 'Atividades por quarteirao',
      'exclusoes_log': 'Exclusoes com justificativa',
      'alertas_emergencia': 'Alertas de emergencia',
    };

    final resumo = <Map<String, dynamic>>[];

    for (final entrada in tabelas.entries) {
      final total = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM ${entrada.key}',
      );
      final sincronizados = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM ${entrada.key} WHERE sincronizado = 1',
      );
      final pendentes = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM ${entrada.key} WHERE sincronizado = 0',
      );
      final erros = await db.rawQuery('''
        SELECT COUNT(*) AS total FROM ${entrada.key}
        WHERE erro_sincronizacao IS NOT NULL
          AND erro_sincronizacao != ''
        ''');

      resumo.add({
        'tabela': entrada.key,
        'modulo': entrada.value,
        'total': total.first['total'] as int? ?? 0,
        'sincronizados': sincronizados.first['total'] as int? ?? 0,
        'pendentes': pendentes.first['total'] as int? ?? 0,
        'erros': erros.first['total'] as int? ?? 0,
      });
    }

    final filaTotal = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_queue',
    );
    final filaPendentes = await db.rawQuery('''
      SELECT COUNT(*) AS total FROM sync_queue
      WHERE status IN ('pending', 'failed', 'processing')
    ''');
    final filaErros = await db.rawQuery('''
      SELECT COUNT(*) AS total FROM sync_queue
      WHERE status = 'failed'
    ''');

    resumo.add({
      'tabela': 'sync_queue',
      'modulo': 'Fila nova de sincronizacao',
      'total': filaTotal.first['total'] as int? ?? 0,
      'sincronizados': 0,
      'pendentes': filaPendentes.first['total'] as int? ?? 0,
      'erros': filaErros.first['total'] as int? ?? 0,
    });

    return resumo;
  }

  Future<List<Map<String, dynamic>>> listarErrosSincronizacao() async {
    final db = await instance.database;
    const tabelas = {
      'pontos_estrategicos': 'Pontos Estrategicos',
      'visitas_pe': 'Visitas PE',
      'visitas_domiciliares': 'Visitas domiciliares',
      'bti_aplicacoes': 'BTI',
      'bti_pontos': 'Pontos BTI',
      'ovitrampas': 'Ovitrampas',
      'ovitrampa_checagens': 'Checagens de ovitrampas',
      'areas_prioritarias': 'Areas prioritarias',
      'lira_lia_visitas': 'LIRA/LIA',
      'quarteiroes': 'Quarteiroes',
      'atividades_quarteirao': 'Atividades por quarteirao',
      'exclusoes_log': 'Exclusoes com justificativa',
      'alertas_emergencia': 'Alertas de emergencia',
    };

    final erros = <Map<String, dynamic>>[];

    for (final entrada in tabelas.entries) {
      final result = await db.query(
        entrada.key,
        columns: ['id', 'erro_sincronizacao'],
        where: "erro_sincronizacao IS NOT NULL AND erro_sincronizacao != ''",
        orderBy: 'id DESC',
        limit: 3,
      );

      for (final item in result) {
        erros.add({
          'modulo': entrada.value,
          'id': item['id'],
          'erro': item['erro_sincronizacao'],
        });
      }
    }

    return erros.take(8).toList();
  }

  Future<List<Map<String, dynamic>>> listarPendentesSincronizacao(
    String tabela,
  ) async {
    final db = await instance.database;
    return await db.query(
      tabela,
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );
  }

  Future<void> marcarSincronizado({
    required String tabela,
    required int id,
    required String sincronizadoEm,
  }) async {
    final db = await instance.database;
    await db.update(
      tabela,
      {
        'sincronizado': 1,
        'sincronizado_em': sincronizadoEm,
        'erro_sincronizacao': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarErroSincronizacao({
    required String tabela,
    required int id,
    required String erro,
  }) async {
    final db = await instance.database;
    await db.update(
      tabela,
      {'sincronizado': 0, 'erro_sincronizacao': erro},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> salvarConfiguracao({
    required String municipio,
    required String agente,
  }) async {
    final db = await instance.database;

    await db.insert('app_config', {
      'chave': 'municipio',
      'valor': municipio,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('app_config', {
      'chave': 'agente',
      'valor': agente,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> salvarValorConfiguracao(String chave, String valor) async {
    final db = await instance.database;

    await db.insert('app_config', {
      'chave': chave,
      'valor': valor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> carregarValorConfiguracao(String chave) async {
    final db = await instance.database;
    final result = await db.query(
      'app_config',
      where: 'chave = ?',
      whereArgs: [chave],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['valor'] as String?;
  }

  Future<Map<String, String>> carregarConfiguracao() async {
    final db = await instance.database;
    final result = await db.query('app_config');

    return {
      for (final item in result)
        item['chave'] as String: item['valor'] as String,
    };
  }

  Future<int> inserirPerfilACE(ACEProfileModel perfil) async {
    final db = await instance.database;

    return await db.insert('ace_profiles', perfil.toMap());
  }

  Future<int> atualizarPerfilACE(ACEProfileModel perfil) async {
    final db = await instance.database;
    final id = perfil.id;

    if (id == null) return 0;

    return await db.update(
      'ace_profiles',
      perfil.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> atualizarSenhaPerfilACE({
    required int id,
    required String senha,
  }) async {
    final db = await instance.database;

    return await db.update(
      'ace_profiles',
      {'senha': senha},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> excluirPerfilACE(int id) async {
    final db = await instance.database;

    return await db.delete('ace_profiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ACEProfileModel>> listarPerfisACE() async {
    final db = await instance.database;
    final result = await db.query('ace_profiles', orderBy: 'nome ASC');

    return result.map((map) => ACEProfileModel.fromMap(map)).toList();
  }

  Future<String> salvarFotoVisitaPE(String origemPath) async {
    final dbPath = await getDatabasesPath();
    final fotosDir = Directory(join(dbPath, 'fotos_visitas_pe'));

    if (!await fotosDir.exists()) {
      await fotosDir.create(recursive: true);
    }

    final extensao = extension(origemPath).isEmpty
        ? '.jpg'
        : extension(origemPath);
    final nomeArquivo =
        'visita_pe_${DateTime.now().millisecondsSinceEpoch}$extensao';
    final destinoPath = join(fotosDir.path, nomeArquivo);

    await File(origemPath).copy(destinoPath);

    return destinoPath;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
