// =============================================================================
// LogiSaúde — APIs REST e telas web
// =============================================================================

const logisaudeStore = require('../lib/logisaude-store');
const web = require('../views/logisaude-web');

function registerLogisaudeRoutes(app, driverStore) {
  // --- APIs LogiSaúde ---
  app.get('/api/logisaude/status', (req, res) => {
    res.json({
      online: true,
      plataforma: 'LogiSaúde',
      municipio: logisaudeStore.getDados().municipio,
      armazenamento: 'JSON local + memória',
      driver: {
        eventos: driverStore.driver_events.length,
        localizacoes: driverStore.driver_locations.length,
      },
      data_hora: new Date().toISOString(),
    });
  });

  app.get('/api/logisaude/dashboard', (req, res) => {
    res.json(logisaudeStore.montarDashboard(driverStore));
  });

  app.get('/api/logisaude/viagens', (req, res) => {
    res.json(logisaudeStore.listarViagens());
  });

  app.post('/api/logisaude/viagens', (req, res) => {
    const registro = logisaudeStore.adicionarViagem(req.body || {});
    res.status(201).json({ sucesso: true, dados: registro });
  });

  function atualizarStatusViagemHandler(id, status, res) {
    if (!status) {
      return res.status(400).json({ sucesso: false, erro: 'Informe status.' });
    }
    const atualizada = logisaudeStore.atualizarStatusViagem(id, status);
    if (!atualizada) {
      return res.status(404).json({ sucesso: false, erro: 'Viagem não encontrada.' });
    }
    return res.json({ sucesso: true, dados: atualizada });
  }

  app.post('/api/logisaude/viagens/atualizar-status', (req, res) => {
    atualizarStatusViagemHandler(req.body?.id, req.body?.status, res);
  });

  app.post('/api/logisaude/viagens/:id/status', (req, res) => {
    atualizarStatusViagemHandler(req.params.id, req.body?.status, res);
  });

  app.get('/api/logisaude/motoristas', (req, res) => {
    res.json(logisaudeStore.listarMotoristas());
  });

  app.post('/api/logisaude/motoristas', (req, res) => {
    const registro = logisaudeStore.adicionarMotorista(req.body || {});
    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/logisaude/veiculos', (req, res) => {
    res.json(logisaudeStore.listarVeiculos());
  });

  app.post('/api/logisaude/veiculos', (req, res) => {
    const registro = logisaudeStore.adicionarVeiculo(req.body || {});
    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/logisaude/pacientes', (req, res) => {
    res.json(logisaudeStore.listarPacientes());
  });

  app.post('/api/logisaude/pacientes', (req, res) => {
    const registro = logisaudeStore.adicionarPaciente(req.body || {});
    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/logisaude/passageiros', (req, res) => {
    res.json(logisaudeStore.listarPassageiros());
  });

  app.post('/api/logisaude/passageiros', (req, res) => {
    const registro = logisaudeStore.adicionarPassageiro(req.body || {});
    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/logisaude/debug', (req, res) => {
    res.json({
      ...logisaudeStore.getDados(),
      driver_events: driverStore.driver_events,
      driver_locations: driverStore.driver_locations,
      driver_trips_status: driverStore.driver_trips_status,
    });
  });

  // --- Telas web LogiSaúde ---
  app.get('/logisaude', (req, res) => {
    res.type('html').send(web.renderDashboard());
  });

  app.get('/logisaude/operacao', (req, res) => {
    res.type('html').send(web.renderOperacao());
  });

  app.get('/logisaude/viagens', (req, res) => {
    res.type('html').send(web.renderViagens());
  });

  app.get('/logisaude/motoristas', (req, res) => {
    res.type('html').send(web.renderMotoristas());
  });

  app.get('/logisaude/veiculos', (req, res) => {
    res.type('html').send(web.renderVeiculos());
  });

  app.get('/logisaude/pacientes', (req, res) => {
    res.type('html').send(web.renderPacientes());
  });

  app.get('/logisaude/rastreamento', (req, res) => {
    res.type('html').send(web.renderRastreamento());
  });

  app.get('/logisaude/sync', (req, res) => {
    res.type('html').send(web.renderSync());
  });

  app.get('/logisaude/debug', (req, res) => {
    res.type('html').send(web.renderDebug());
  });
}

module.exports = { registerLogisaudeRoutes };
