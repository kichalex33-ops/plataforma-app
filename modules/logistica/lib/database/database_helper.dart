import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/exclusao_log_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('logisaude.db');
    await ensureLogisticaMvpSchema(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return openDatabase(filePath, version: 1, onCreate: _createDB);
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await _createConfigTable(db);
    await _createSyncQueueTable(db);
    await _createSyncLogsTable(db);
    await _createAuditoriaEventosTable(db);
    await _createExclusoesLogTable(db);
    await _createAlertasOperacionaisTable(db);
    await _createTransportesTables(db);
    await _createPacientesTable(db);
    await _createMapasTable(db);
    await _createRastreamentoViagemTable(db);
    await _createMensagensTable(db);
    await _createChecklistsTable(db);
  }

  Future<void> _createConfigTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_config (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
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

  Future<void> _createSyncLogsTable(Database db) async {
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
        device_id TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
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
        motorista TEXT,
        municipio TEXT,
        data_hora TEXT NOT NULL,
        origem TEXT NOT NULL DEFAULT 'logisaude_driver',
        sincronizado INTEGER NOT NULL DEFAULT 0,
        sincronizado_em TEXT,
        erro_sincronizacao TEXT
      )
    ''');
  }

  Future<void> _createAlertasOperacionaisTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alertas_operacionais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motorista TEXT,
        municipio TEXT,
        data_hora TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        status TEXT NOT NULL DEFAULT 'registrado',
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }

  Future<void> _createTransportesTables(Database db) async {
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

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_viagens_motorista ON transportes_viagens(motorista_id, data_hora_saida)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_passageiros_viagem ON transportes_passageiros(viagem_id)',
    );
  }

  Future<void> _createPacientesTable(Database db) async {
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
  }

  Future<void> _createMapasTable(Database db) async {
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
      'CREATE INDEX IF NOT EXISTS idx_rastreamento_viagem ON rastreamento_viagem(viagem_id, timestamp)',
    );
  }

  Future<void> _createMensagensTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mensagens (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        motorista_id TEXT,
        viagem_id TEXT,
        direcao TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }

  Future<void> _createChecklistsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklists (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        viagem_id TEXT NOT NULL,
        motorista_id TEXT NOT NULL,
        tipo TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }

  Future<void> ensureLogisticaMvpSchema(Database db) async {
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'prioridade',
      "TEXT NOT NULL DEFAULT 'normal'",
    );
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'observacoes_central',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'unidade_destino',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'data_consulta',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'horario_consulta',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'destino_principal',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'status_operacional',
      'TEXT',
    );
    await _addColumnIfMissing(db, 'transportes_viagens', 'km_saida', 'REAL');
    await _addColumnIfMissing(
      db,
      'transportes_viagens',
      'horario_saida_confirmada',
      'TEXT',
    );

    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'acompanhante',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'acessibilidade',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'telefone',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'endereco_embarque',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'cadeirante',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'mobilidade_reduzida',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'acompanhante_obrigatorio',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'transportes_passageiros',
      'observacoes_embarque',
      'TEXT',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS viagem_preparacoes (
        id TEXT PRIMARY KEY,
        municipio_id TEXT NOT NULL,
        viagem_id TEXT NOT NULL,
        motorista_id TEXT NOT NULL,
        veiculo_id TEXT,
        km_inicial REAL,
        checklist_concluido INTEGER NOT NULL DEFAULT 0,
        checklist_payload_json TEXT,
        horario_preparacao TEXT NOT NULL,
        horario_saida TEXT,
        status TEXT NOT NULL DEFAULT 'preparacao',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (viagem_id) REFERENCES transportes_viagens (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_viagem_preparacoes_viagem ON viagem_preparacoes(viagem_id)',
    );
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> salvarConfiguracao({
    required String municipio,
    required String motorista,
  }) async {
    await salvarValorConfiguracao('municipio', municipio);
    await salvarValorConfiguracao('motorista', motorista);
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

  Future<int> inserirExclusaoLog(ExclusaoLogModel log) async {
    final db = await instance.database;
    return db.insert('exclusoes_log', log.toMap());
  }

  Future<List<ExclusaoLogModel>> listarExclusoesLog() async {
    final db = await instance.database;
    final result = await db.query('exclusoes_log', orderBy: 'id DESC');
    return result.map(ExclusaoLogModel.fromMap).toList();
  }

  Future<int> contarPendentesSincronizacao() async {
    final db = await instance.database;
    var total = 0;

    for (final table in _syncStatusTables) {
      if (!await _tableExists(db, table)) continue;
      final result = await db.rawQuery(
        "SELECT COUNT(*) AS total FROM $table WHERE sync_status IN ('pending', 'failed', 'processing')",
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
    final resumo = <Map<String, dynamic>>[];

    for (final entry in _syncModules.entries) {
      if (!await _tableExists(db, entry.key)) continue;
      resumo.add(await _resumoTabela(db, entry.key, entry.value));
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
      'modulo': 'Fila de sincronizacao',
      'total': filaTotal.first['total'] as int? ?? 0,
      'sincronizados': 0,
      'pendentes': filaPendentes.first['total'] as int? ?? 0,
      'erros': filaErros.first['total'] as int? ?? 0,
    });

    return resumo;
  }

  Future<List<Map<String, dynamic>>> listarErrosSincronizacao() async {
    final db = await instance.database;
    final erros = <Map<String, dynamic>>[];

    final result = await db.query(
      'sync_queue',
      columns: ['entity_type', 'entity_id', 'error_message'],
      where: "status = 'failed' AND error_message IS NOT NULL",
      orderBy: 'updated_at DESC',
      limit: 8,
    );

    for (final item in result) {
      erros.add({
        'modulo': item['entity_type'],
        'id': item['entity_id'],
        'erro': item['error_message'],
      });
    }

    return erros;
  }

  Future<List<Map<String, dynamic>>> listarPendentesSincronizacao(
    String tabela,
  ) async {
    final db = await instance.database;
    return db.query(
      tabela,
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> marcarSincronizado({
    required String tabela,
    required Object id,
    required String sincronizadoEm,
  }) async {
    final db = await instance.database;
    await db.update(
      tabela,
      {'sync_status': 'synced', 'updated_at': sincronizadoEm},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarErroSincronizacao({
    required String tabela,
    required Object id,
    required String erro,
  }) async {
    final db = await instance.database;
    await db.update(
      tabela,
      {'sync_status': 'failed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> _resumoTabela(
    Database db,
    String tabela,
    String modulo,
  ) async {
    final total = await db.rawQuery('SELECT COUNT(*) AS total FROM $tabela');
    final sincronizados = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM $tabela WHERE sync_status = 'synced'",
    );
    final pendentes = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM $tabela WHERE sync_status IN ('pending', 'processing')",
    );
    final erros = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM $tabela WHERE sync_status = 'failed'",
    );

    return {
      'tabela': tabela,
      'modulo': modulo,
      'total': total.first['total'] as int? ?? 0,
      'sincronizados': sincronizados.first['total'] as int? ?? 0,
      'pendentes': pendentes.first['total'] as int? ?? 0,
      'erros': erros.first['total'] as int? ?? 0,
    };
  }

  Future<bool> _tableExists(Database db, String table) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    return result.isNotEmpty;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  static const _syncModules = {
    'transportes_motoristas': 'Motoristas',
    'transportes_veiculos': 'Veiculos',
    'transportes_viagens': 'Viagens',
    'transportes_passageiros': 'Passageiros',
    'pacientes': 'Pacientes',
    'rastreamento_viagem': 'Rastreamento',
    'mapas_camadas': 'Mapas',
    'mensagens': 'Mensagens',
    'checklists': 'Checklists',
    'auditoria_eventos': 'Auditoria',
    'alertas_operacionais': 'Alertas operacionais',
  };

  static const _syncStatusTables = [
    'transportes_motoristas',
    'transportes_veiculos',
    'transportes_viagens',
    'transportes_passageiros',
    'pacientes',
    'rastreamento_viagem',
    'mapas_camadas',
    'mensagens',
    'checklists',
    'auditoria_eventos',
    'alertas_operacionais',
  ];
}
