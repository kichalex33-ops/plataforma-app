// =============================================================================
// Driver App API — eventos, localizações, viagens e status
// =============================================================================

function registerDriverRoutes(app, driverStore, logisaudeStore) {
  app.post('/api/driver/events', (req, res) => {
    const registro = driverStore.registrarDriver(
      driverStore.driver_events,
      req.body || {},
      'event',
    );
    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/driver/events', (req, res) => {
    res.json(driverStore.respostaDriver(driverStore.driver_events));
  });

  app.post('/api/driver/locations', (req, res) => {
    const registro = driverStore.registrarDriver(
      driverStore.driver_locations,
      req.body || {},
      'location',
    );
    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/driver/locations', (req, res) => {
    res.json(driverStore.respostaDriver(driverStore.driver_locations));
  });

  app.get('/api/driver/trips', (req, res) => {
    const viagens = logisaudeStore.viagensParaDriverApp();
    res.json({
      total: viagens.length,
      municipio: logisaudeStore.getDados().municipio,
      items: viagens,
    });
  });

  app.post('/api/driver/trips/status', (req, res) => {
    const body = req.body || {};
    const registro = driverStore.registrarDriver(
      driverStore.driver_trips_status,
      body,
      'trip-status',
    );

    if (body.viagemId || body.viagem_id) {
      const viagemId = body.viagemId || body.viagem_id;
      const status = body.status || 'em_andamento';
      const atualizada = logisaudeStore.atualizarStatusViagem(viagemId, status);
      if (!atualizada) {
        logisaudeStore.registrarFalhaSync(
          `Status recebido para viagem inexistente: ${viagemId}`,
        );
      }
    }

    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/driver/trips/status', (req, res) => {
    res.json(driverStore.respostaDriver(driverStore.driver_trips_status));
  });
}

module.exports = { registerDriverRoutes };
