// =============================================================================
// ACE Territorial — APIs e painel existentes (nao remover endpoints)
// =============================================================================

const ace = require('../lib/ace-store');

function criarRotas(app, nome, lista) {
  app.get(`/api/${nome}`, (req, res) => {
    res.json(lista);
  });

  app.post(`/api/${nome}`, (req, res) => {
    const registro = ace.montarRegistro(lista, req.body || {});
    lista.push(registro);

    res.status(201).json({
      sucesso: true,
      dados: registro,
    });
  });
}

function renderPainelDriver() {
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Painel de Teste Driver App</title>
  <style>
    :root { color-scheme: light; font-family: Arial, sans-serif; color: #17202a; background: #f4f6f8; }
    body { margin: 0; padding: 24px; }
    header { display: flex; gap: 16px; align-items: center; justify-content: space-between; margin-bottom: 20px; }
    h1 { margin: 0; font-size: 24px; }
    button { border: 0; border-radius: 6px; background: #1565c0; color: white; padding: 10px 14px; font-weight: 700; cursor: pointer; }
    main { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; }
    section { background: white; border: 1px solid #dfe5ec; border-radius: 8px; padding: 16px; min-height: 180px; }
    h2 { margin: 0 0 12px; font-size: 18px; }
    .meta { color: #5f6f7d; font-size: 13px; margin-bottom: 10px; }
    pre { white-space: pre-wrap; word-break: break-word; background: #f8fafc; border: 1px solid #e1e7ef; border-radius: 6px; padding: 12px; max-height: 420px; overflow: auto; }
    .top-links { margin-bottom: 12px; font-size: 14px; }
    .top-links a { color: #1565c0; margin-right: 12px; }
  </style>
</head>
<body>
  <div class="top-links"><a href="/">← Portal</a> <a href="/logisaude">LogiSaúde</a></div>
  <header>
    <div>
      <h1>Painel de Teste Driver App (ACE)</h1>
      <div class="meta" id="ultimo">Último recebimento: carregando...</div>
    </div>
    <button type="button" onclick="carregar()">Atualizar</button>
  </header>
  <main>
    <section><h2>Eventos recebidos</h2><div class="meta" id="eventos-meta"></div><pre id="eventos">[]</pre></section>
    <section><h2>Localizações recebidas</h2><div class="meta" id="localizacoes-meta"></div><pre id="localizacoes">[]</pre></section>
    <section><h2>Status de viagens</h2><div class="meta" id="status-meta"></div><pre id="status">[]</pre></section>
  </main>
  <script>
    async function carregarBloco(url, preId, metaId) {
      const resposta = await fetch(url);
      const dados = await resposta.json();
      document.getElementById(preId).textContent = JSON.stringify(dados.items, null, 2);
      document.getElementById(metaId).textContent = 'Total: ' + dados.total;
      return dados.lastReceivedAt;
    }
    async function carregar() {
      const ultimos = await Promise.all([
        carregarBloco('/api/driver/events', 'eventos', 'eventos-meta'),
        carregarBloco('/api/driver/locations', 'localizacoes', 'localizacoes-meta'),
        carregarBloco('/api/driver/trips/status', 'status', 'status-meta'),
      ]);
      const ultimo = ultimos.filter(Boolean).sort().pop();
      document.getElementById('ultimo').textContent = 'Último recebimento: ' + (ultimo || 'nenhum dado recebido');
    }
    carregar();
  </script>
</body>
</html>`;
}

function registerAceRoutes(app, driverStore) {
  app.get('/api/status', (req, res) => {
    res.json({
      online: true,
      servidor: 'Plataforma Territorial Epidemiologica',
      modo: 'Servidor local',
      armazenamento: 'Memoria temporaria JSON',
      futuro_banco: 'PostgreSQL/Supabase',
      logisaude: true,
      driver: {
        eventos: driverStore.driver_events.length,
        localizacoes: driverStore.driver_locations.length,
        status_viagens: driverStore.driver_trips_status.length,
        ultimo_recebimento: driverStore.driver_ultimo_recebimento,
      },
      data_hora: new Date().toISOString(),
    });
  });

  app.get('/api/dashboard', (req, res) => {
    const pesEmDia = ace.contarPorStatus(ace.pontos_estrategicos, 'Em dia');
    const pesVencendo = ace.contarPorStatus(ace.pontos_estrategicos, 'Vencendo');
    const pesAtrasados = ace.contarPorStatus(ace.pontos_estrategicos, 'Atrasado');
    const focosPositivos =
      ace.visitas_pe.filter(ace.ehFocoPositivo).length +
      ace.visitas_domiciliares.filter(ace.ehFocoPositivo).length +
      ace.coletas_larvarias.filter(ace.ehFocoPositivo).length +
      ace.ovitrampa_checagens.filter(ace.ehFocoPositivo).length;
    const ovitrampasPositivas =
      ace.ovitrampas.filter(ace.ehFocoPositivo).length +
      ace.ovitrampa_checagens.filter(ace.ehFocoPositivo).length;

    res.json({
      totalPEs: ace.pontos_estrategicos.length,
      ativos: pesEmDia,
      vencendo: pesVencendo,
      atrasados: pesAtrasados,
      visitasPE: ace.visitas_pe.length,
      visitasDomiciliares: ace.visitas_domiciliares.length,
      aplicacoesBTI: ace.bti.length,
      ovitrampasCadastradas: ace.ovitrampas.length,
      ovitrampasPositivas,
      coletasLarvarias: ace.coletas_larvarias.length,
      casosDengue: ace.casos_dengue.length,
      casosEsporotricose: ace.esporotricose.length,
      exclusoes: ace.exclusoes_log.length,
      alertasEmergencia: ace.alertas_emergencia.length,
      focosPositivos,
      pes_em_dia: pesEmDia,
      pes_vencendo: pesVencendo,
      pes_atrasados: pesAtrasados,
      total_visitas_pe: ace.visitas_pe.length,
      visitas_domiciliares: ace.visitas_domiciliares.length,
      focos_positivos: focosPositivos,
      aplicacoes_bti: ace.bti.length,
      ovitrampas_cadastradas: ace.ovitrampas.length,
      ovitrampas_positivas: ovitrampasPositivas,
      coletas_larvarias: ace.coletas_larvarias.length,
      casos_dengue: ace.casos_dengue.length,
      casos_esporotricose: ace.esporotricose.length,
      exclusoes_log: ace.exclusoes_log.length,
      alertas_emergencia: ace.alertas_emergencia.length,
    });
  });

  app.get('/api/mapa/dados', (req, res) => {
    res.json({
      pes: ace.pontos_estrategicos,
      bti: ace.bti,
      ovitrampas: ace.ovitrampas,
      coletas_larvarias: ace.coletas_larvarias,
      casos_dengue: ace.casos_dengue,
      esporotricose: ace.esporotricose,
      quarteiroes: ace.quarteiroes,
      alertas_emergencia: ace.alertas_emergencia,
    });
  });

  app.get('/api/pes', (req, res) => {
    res.json(ace.pontos_estrategicos);
  });

  app.post('/api/pes', (req, res) => {
    const registro = ace.montarRegistro(ace.pontos_estrategicos, req.body || {});
    ace.pontos_estrategicos.push(registro);
    res.status(201).json({ sucesso: true, dados: registro });
  });

  app.get('/api/tubitos/status', (req, res) => {
    res.json({
      ultimo_tubito: ace.ultimo_tubito,
      proximo_tubito: ace.ultimo_tubito + 1,
    });
  });

  app.post('/api/tubitos/reservar', (req, res) => {
    const quantidade = Math.max(0, Number(req.body?.quantidade) || 0);
    if (!quantidade) {
      return res.status(400).json({
        sucesso: false,
        erro: 'Informe a quantidade de tubitos.',
      });
    }
    const primeiro = ace.ultimo_tubito + 1;
    const ultimo = ace.ultimo_tubito + quantidade;
    ace.ultimo_tubito = ultimo;
    res.status(201).json({
      sucesso: true,
      primeiro_numero: primeiro,
      ultimo_numero: ultimo,
      quantidade,
      municipio: req.body?.municipio || null,
      ace_responsavel: req.body?.ace_responsavel || req.body?.agente || null,
      sincronizado_em: new Date().toISOString(),
    });
  });

  criarRotas(app, 'perfis-ace', ace.perfis_ace);
  criarRotas(app, 'visitas-pe', ace.visitas_pe);
  criarRotas(app, 'visitas-domiciliares', ace.visitas_domiciliares);
  criarRotas(app, 'bti', ace.bti);
  criarRotas(app, 'ovitrampas', ace.ovitrampas);
  criarRotas(app, 'ovitrampas/checagens', ace.ovitrampa_checagens);
  criarRotas(app, 'coletas-larvarias', ace.coletas_larvarias);
  criarRotas(app, 'casos-dengue', ace.casos_dengue);
  criarRotas(app, 'esporotricose', ace.esporotricose);
  criarRotas(app, 'quarteiroes', ace.quarteiroes);
  criarRotas(app, 'atividades-quarteirao', ace.atividades_quarteirao);
  criarRotas(app, 'exclusoes-log', ace.exclusoes_log);
  criarRotas(app, 'alertas-emergencia', ace.alertas_emergencia);
  criarRotas(app, 'localidades', ace.localidades);
  criarRotas(app, 'setores-operacionais', ace.setores_operacionais);
  criarRotas(app, 'quarteiroes-operacionais', ace.quarteiroes_operacionais);
  criarRotas(app, 'atribuicoes-setor', ace.atribuicoes_setor);
  criarRotas(app, 'progresso-quarteirao', ace.progresso_quarteirao);
  criarRotas(app, 'auditoria-eventos', ace.auditoria_eventos);
  criarRotas(app, 'transportes/motoristas', ace.transportes_motoristas);
  criarRotas(app, 'transportes/veiculos', ace.transportes_veiculos);
  criarRotas(app, 'transportes/viagens', ace.transportes_viagens);
  criarRotas(app, 'transportes/passageiros', ace.transportes_passageiros);
  criarRotas(app, 'pacientes', ace.pacientes);
  criarRotas(app, 'rastreamento-viagem', ace.rastreamento_viagem);
  criarRotas(app, 'mapas/camadas', ace.mapas_camadas);

  app.get('/painel', (req, res) => {
    res.type('html').send(renderPainelDriver());
  });

  app.get('/painel-ace', (req, res) => {
    res.redirect('/painel');
  });
}

module.exports = { registerAceRoutes };
