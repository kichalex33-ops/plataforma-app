const NAV_ITEMS = [
  { key: 'dashboard', path: '/logisaude', label: 'Dashboard' },
  { key: 'operacao', path: '/logisaude/operacao', label: 'Operação' },
  { key: 'viagens', path: '/logisaude/viagens', label: 'Viagens' },
  { key: 'motoristas', path: '/logisaude/motoristas', label: 'Motoristas' },
  { key: 'veiculos', path: '/logisaude/veiculos', label: 'Veículos' },
  { key: 'pacientes', path: '/logisaude/pacientes', label: 'Pacientes' },
  { key: 'rastreamento', path: '/logisaude/rastreamento', label: 'Rastreamento' },
  { key: 'sync', path: '/logisaude/sync', label: 'Sync' },
  { key: 'debug', path: '/logisaude/debug', label: 'Debug' },
];

function layout(activeKey, title, bodyHtml, extraScript = '') {
  const nav = NAV_ITEMS.map(
    (item) =>
      `<a href="${item.path}" class="${item.key === activeKey ? 'active' : ''}">${item.label}</a>`,
  ).join('');

  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title} — LogiSaúde</title>
  <link rel="stylesheet" href="/logisaude.css">
</head>
<body>
  <div class="ls-layout">
    <aside class="ls-sidebar">
      <div class="ls-brand">LogiSaúde</div>
      <div class="ls-subbrand">Operação logística municipal</div>
      <nav class="ls-nav">${nav}</nav>
      <p style="margin-top:24px;font-size:12px;opacity:.75;"><a href="/" style="color:#fff;">← Portal</a></p>
    </aside>
    <main class="ls-main">
      <header class="ls-header">
        <div>
          <h1>${title}</h1>
          <div class="ls-meta">Ambiente de testes — memória / JSON local</div>
        </div>
        <a class="btn btn-muted" href="/painel">Driver painel</a>
      </header>
      ${bodyHtml}
    </main>
  </div>
  ${extraScript}
</body>
</html>`;
}

function renderDashboard() {
  return layout(
    'dashboard',
    'Dashboard',
    `<div class="cards-grid" id="cards"></div>
     <section class="panel"><h2>Resumo rápido</h2><p id="resumo">Carregando...</p></section>`,
    `<script>
      async function carregar() {
        const res = await fetch('/api/logisaude/dashboard');
        const d = await res.json();
        const cards = [
          ['Viagens do dia', d.viagens_do_dia],
          ['Em andamento', d.viagens_em_andamento],
          ['Pacientes / passageiros', d.pacientes_passageiros],
          ['Motoristas ativos', d.motoristas_ativos],
          ['Veículos disponíveis', d.veiculos_disponiveis],
          ['Eventos recebidos', d.eventos_recebidos],
          ['Localizações', d.localizacoes_recebidas],
          ['Pendências sync', d.pendencias_sync],
        ];
        document.getElementById('cards').innerHTML = cards.map(([label, value]) =>
          '<article class="stat-card"><div class="label">' + label + '</div><div class="value">' + value + '</div></article>'
        ).join('');
        document.getElementById('resumo').textContent =
          'Município: ' + d.municipio + ' — atualizado em ' + new Date(d.data_hora).toLocaleString('pt-BR');
      }
      carregar();
    </script>`,
  );
}

function renderOperacao() {
  return layout(
    'operacao',
    'Operação',
    `<section class="panel"><h2>Viagens em operação</h2><div id="lista">Carregando...</div></section>`,
    `<script>
      async function nomeMotorista(id, motoristas) {
        const m = motoristas.find(x => x.id === id);
        return m ? m.nome : '-';
      }
      async function nomeVeiculo(id, veiculos) {
        const v = veiculos.find(x => x.id === id);
        return v ? v.nome : '-';
      }
      async function acao(id, status) {
        await fetch('/api/logisaude/viagens/atualizar-status', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id, status })
        });
        carregar();
      }
      async function carregar() {
        const [viagens, motoristas, veiculos, passageiros] = await Promise.all([
          fetch('/api/logisaude/viagens').then(r => r.json()),
          fetch('/api/logisaude/motoristas').then(r => r.json()),
          fetch('/api/logisaude/veiculos').then(r => r.json()),
          fetch('/api/logisaude/passageiros').then(r => r.json()),
        ]);
        const rows = await Promise.all(viagens.map(async v => {
          const pax = (v.passageiro_ids || []).map(pid => {
            const p = passageiros.find(x => x.id === pid);
            return p ? p.nome : pid;
          }).join(', ');
          return '<tr><td>' + v.origem + ' → ' + v.destino + '</td><td><span class="badge">' + v.status + '</span></td><td>' +
            await nomeMotorista(v.motorista_id, motoristas) + '</td><td>' +
            await nomeVeiculo(v.veiculo_id, veiculos) + '</td><td>' + (pax || '-') + '</td><td class="actions">' +
            '<button class="btn-sm btn-success" onclick="acao(\\'' + v.id + '\\',\\'em_andamento\\')">Despachar</button>' +
            '<button class="btn-sm btn-danger" onclick="acao(\\'' + v.id + '\\',\\'cancelada\\')">Cancelar</button>' +
            '<button class="btn-sm btn-warning" onclick="acao(\\'' + v.id + '\\',\\'concluida\\')">Concluir</button>' +
            '</td></tr>';
        }));
        document.getElementById('lista').innerHTML = '<table><thead><tr><th>Viagem</th><th>Status</th><th>Motorista</th><th>Veículo</th><th>Passageiros</th><th>Ações</th></tr></thead><tbody>' +
          rows.join('') + '</tbody></table>';
      }
      carregar();
    </script>`,
  );
}

function renderViagens() {
  return layout(
    'viagens',
    'Viagens',
    `<section class="panel"><h2>Nova viagem</h2>
      <form id="form-viagem" class="form-grid">
        <div><label>Origem</label><input name="origem" required></div>
        <div><label>Destino</label><input name="destino" required></div>
        <div><label>Motorista</label><select name="motorista_id" id="sel-motorista"></select></div>
        <div><label>Veículo</label><select name="veiculo_id" id="sel-veiculo"></select></div>
        <div><label>Passageiro</label><select name="passageiro_id" id="sel-passageiro"></select></div>
        <div><label>Data/hora saída</label><input name="data_hora_saida" type="datetime-local"></div>
        <div style="grid-column:1/-1"><button class="btn btn-ls" type="submit">Criar viagem</button></div>
      </form>
    </section>
    <section class="panel"><h2>Lista de viagens</h2><div id="lista">Carregando...</div></section>`,
    `<script>
      async function carregarSelects() {
        const [motoristas, veiculos, passageiros] = await Promise.all([
          fetch('/api/logisaude/motoristas').then(r => r.json()),
          fetch('/api/logisaude/veiculos').then(r => r.json()),
          fetch('/api/logisaude/passageiros').then(r => r.json()),
        ]);
        document.getElementById('sel-motorista').innerHTML = motoristas.map(m => '<option value="' + m.id + '">' + m.nome + '</option>').join('');
        document.getElementById('sel-veiculo').innerHTML = veiculos.map(v => '<option value="' + v.id + '">' + v.nome + '</option>').join('');
        document.getElementById('sel-passageiro').innerHTML = passageiros.map(p => '<option value="' + p.id + '">' + p.nome + '</option>').join('');
      }
      async function carregarLista() {
        const viagens = await fetch('/api/logisaude/viagens').then(r => r.json());
        document.getElementById('lista').innerHTML = '<table><thead><tr><th>ID</th><th>Rota</th><th>Status</th><th>Saída</th></tr></thead><tbody>' +
          viagens.map(v => '<tr><td>' + v.id + '</td><td>' + v.origem + ' → ' + v.destino + '</td><td>' + v.status + '</td><td>' + v.data_hora_saida + '</td></tr>').join('') +
          '</tbody></table>';
      }
      document.getElementById('form-viagem').addEventListener('submit', async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        await fetch('/api/logisaude/viagens', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            origem: fd.get('origem'),
            destino: fd.get('destino'),
            motorista_id: fd.get('motorista_id'),
            veiculo_id: fd.get('veiculo_id'),
            passageiro_ids: [fd.get('passageiro_id')],
            data_hora_saida: fd.get('data_hora_saida') ? new Date(fd.get('data_hora_saida')).toISOString() : new Date().toISOString(),
          })
        });
        e.target.reset();
        carregarLista();
      });
      carregarSelects();
      carregarLista();
    </script>`,
  );
}

function renderCadastroPage(activeKey, title, entidade, camposHtml) {
  return layout(
    activeKey,
    title,
    `<section class="panel"><h2>Novo cadastro</h2><form id="form" class="form-grid">${camposHtml}<div style="grid-column:1/-1"><button class="btn btn-ls" type="submit">Salvar</button></div></form></section>
     <section class="panel"><h2>Lista</h2><div id="lista">Carregando...</div></section>`,
    `<script>
      async function carregarLista() {
        const dados = await fetch('/api/logisaude/${entidade}').then(r => r.json());
        const cols = Object.keys(dados[0] || { id: '', nome: '' });
        document.getElementById('lista').innerHTML = '<table><thead><tr>' + cols.map(c => '<th>' + c + '</th>').join('') + '</tr></thead><tbody>' +
          dados.map(item => '<tr>' + cols.map(c => '<td>' + (item[c] ?? '') + '</td>').join('') + '</tr>').join('') + '</tbody></table>';
      }
      document.getElementById('form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const body = {};
        fd.forEach((v, k) => body[k] = v);
        await fetch('/api/logisaude/${entidade}', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
        e.target.reset();
        carregarLista();
      });
      carregarLista();
    </script>`,
  );
}

function renderMotoristas() {
  return renderCadastroPage(
    'motoristas',
    'Motoristas',
    'motoristas',
    '<div><label>Nome</label><input name="nome" required></div><div><label>Telefone</label><input name="telefone"></div>',
  );
}

function renderVeiculos() {
  return renderCadastroPage(
    'veiculos',
    'Veículos',
    'veiculos',
    '<div><label>Nome</label><input name="nome" required></div><div><label>Placa</label><input name="placa"></div><div><label>Tipo</label><input name="tipo" placeholder="ambulancia, van, carro"></div>',
  );
}

function renderPacientes() {
  return renderCadastroPage(
    'pacientes',
    'Pacientes / Passageiros',
    'pacientes',
    '<div><label>Nome</label><input name="nome" required></div><div><label>Motivo</label><input name="motivo" placeholder="cardiologia, exame..."></div>',
  );
}

function renderRastreamento() {
  return layout(
    'rastreamento',
    'Rastreamento',
    `<section class="panel"><h2>Mapa (placeholder)</h2><div class="map-placeholder">Mapa visual — integração futura</div></section>
     <section class="panel"><h2>Localizações recebidas</h2><div id="lista">Carregando...</div></section>`,
    `<script>
      async function carregar() {
        const dados = await fetch('/api/driver/locations').then(r => r.json());
        const items = dados.items || [];
        document.getElementById('lista').innerHTML = items.length ? '<table><thead><tr><th>Motorista</th><th>Viagem</th><th>Lat</th><th>Lng</th><th>Recebido</th></tr></thead><tbody>' +
          items.map(i => '<tr><td>' + (i.motoristaId || i.motorista_id || '-') + '</td><td>' + (i.viagemId || i.viagem_id || '-') + '</td><td>' + i.latitude + '</td><td>' + i.longitude + '</td><td>' + (i.received_at || '-') + '</td></tr>').join('') +
          '</tbody></table>' : '<p>Nenhuma localização recebida ainda.</p>';
      }
      carregar();
    </script>`,
  );
}

function renderSync() {
  return layout(
    'sync',
    'Sincronização',
    `<section class="panel"><h2>Eventos do app motorista</h2><pre id="eventos">[]</pre></section>
     <section class="panel"><h2>Status de viagens recebidos</h2><pre id="status">[]</pre></section>
     <section class="panel"><h2>Falhas registradas</h2><pre id="falhas">[]</pre></section>`,
    `<script>
      async function carregar() {
        const [eventos, status, debug] = await Promise.all([
          fetch('/api/driver/events').then(r => r.json()),
          fetch('/api/driver/trips/status').then(r => r.json()),
          fetch('/api/logisaude/debug').then(r => r.json()),
        ]);
        document.getElementById('eventos').textContent = JSON.stringify(eventos.items || [], null, 2);
        document.getElementById('status').textContent = JSON.stringify(status.items || [], null, 2);
        document.getElementById('falhas').textContent = JSON.stringify(debug.falhas_sync || [], null, 2);
      }
      carregar();
    </script>`,
  );
}

function renderDebug() {
  return layout(
    'debug',
    'Debug JSON',
    `<section class="panel"><p>JSON bruto das coleções LogiSaúde e dados do driver app.</p><pre class="debug-json" id="json">Carregando...</pre></section>`,
    `<script>
      fetch('/api/logisaude/debug').then(r => r.json()).then(d => {
        document.getElementById('json').textContent = JSON.stringify(d, null, 2);
      });
    </script>`,
  );
}

function renderRastreamentoVivo() {
  return layout(
    'rastreamento',
    'Rastreamento',
    `<section class="panel live-route-panel">
      <div class="panel-title-row">
        <div>
          <h2>Rota ao vivo do app motorista</h2>
          <div class="ls-meta" id="rota-meta">Aguardando pontos do app...</div>
        </div>
        <span class="live-pill" id="rota-status">offline</span>
      </div>
      <div class="route-map" id="route-map">
        <div class="route-empty">Nenhuma localizacao recebida ainda.</div>
      </div>
    </section>
    <section class="panel">
      <h2>Ultimos pontos recebidos</h2>
      <div id="lista">Carregando...</div>
    </section>`,
    `<script>
      function valor(item, ...chaves) {
        for (const chave of chaves) {
          if (item[chave] !== undefined && item[chave] !== null && item[chave] !== '') return item[chave];
        }
        return '-';
      }

      function numero(item, ...chaves) {
        const bruto = valor(item, ...chaves);
        const n = Number(bruto);
        return Number.isFinite(n) ? n : null;
      }

      function desenharRota(items) {
        const map = document.getElementById('route-map');
        const pontos = items
          .map((item) => ({
            lat: numero(item, 'latitude', 'lat'),
            lng: numero(item, 'longitude', 'lng', 'lon'),
            viagem: valor(item, 'viagemId', 'viagem_id'),
            motorista: valor(item, 'motorista_nome', 'motoristaId', 'motorista_id'),
            recebido: item.received_at || item.created_at || '',
          }))
          .filter((p) => p.lat !== null && p.lng !== null)
          .slice(-30);

        if (!pontos.length) {
          map.innerHTML = '<div class="route-empty">Nenhuma localizacao recebida ainda.</div>';
          document.getElementById('rota-status').textContent = 'offline';
          document.getElementById('rota-status').className = 'live-pill';
          document.getElementById('rota-meta').textContent = 'Aguardando pontos do app motorista.';
          return;
        }

        const minLat = Math.min(...pontos.map((p) => p.lat));
        const maxLat = Math.max(...pontos.map((p) => p.lat));
        const minLng = Math.min(...pontos.map((p) => p.lng));
        const maxLng = Math.max(...pontos.map((p) => p.lng));
        const latSpan = Math.max(maxLat - minLat, 0.0001);
        const lngSpan = Math.max(maxLng - minLng, 0.0001);
        const coords = pontos.map((p) => {
          const x = 8 + ((p.lng - minLng) / lngSpan) * 84;
          const y = 92 - ((p.lat - minLat) / latSpan) * 84;
          return { ...p, x, y };
        });
        const path = coords.map((p) => p.x + ',' + p.y).join(' ');
        const ultimo = coords[coords.length - 1];

        map.innerHTML =
          '<svg class="route-svg" viewBox="0 0 100 100" preserveAspectRatio="none" aria-label="Rota recebida do app">' +
            '<polyline class="route-line" points="' + path + '" />' +
            coords.map((p, index) =>
              '<circle class="' + (index === coords.length - 1 ? 'route-dot route-dot-current' : 'route-dot') + '" cx="' + p.x + '" cy="' + p.y + '" r="' + (index === coords.length - 1 ? 2.4 : 1.25) + '" />'
            ).join('') +
          '</svg>' +
          '<div class="route-current-card"><strong>Ultimo ponto</strong><span>' +
          ultimo.motorista + ' / ' + ultimo.viagem + '</span><span>' +
          ultimo.lat.toFixed(6) + ', ' + ultimo.lng.toFixed(6) + '</span></div>';

        document.getElementById('rota-status').textContent = 'ao vivo';
        document.getElementById('rota-status').className = 'live-pill online';
        document.getElementById('rota-meta').textContent =
          pontos.length + ' pontos na trilha. Ultima atualizacao: ' +
          (ultimo.recebido ? new Date(ultimo.recebido).toLocaleString('pt-BR') : new Date().toLocaleString('pt-BR'));
      }

      async function carregar() {
        const dados = await fetch('/api/driver/locations').then(r => r.json());
        const items = dados.items || dados.data || [];
        desenharRota(items);
        const recentes = items.slice(-20).reverse();
        document.getElementById('lista').innerHTML = recentes.length ? '<table><thead><tr><th>Motorista</th><th>Viagem</th><th>Lat</th><th>Lng</th><th>Vel.</th><th>Recebido</th></tr></thead><tbody>' +
          recentes.map(i => '<tr><td>' + valor(i, 'motorista_nome', 'motoristaId', 'motorista_id') + '</td><td>' + valor(i, 'viagemId', 'viagem_id') + '</td><td>' + valor(i, 'latitude', 'lat') + '</td><td>' + valor(i, 'longitude', 'lng', 'lon') + '</td><td>' + valor(i, 'velocidade') + '</td><td>' + (i.received_at || i.created_at || '-') + '</td></tr>').join('') +
          '</tbody></table>' : '<p>Nenhuma localizacao recebida ainda.</p>';
      }
      carregar();
      setInterval(carregar, 3000);
    </script>`,
  );
}

module.exports = {
  renderDashboard,
  renderOperacao,
  renderViagens,
  renderMotoristas,
  renderVeiculos,
  renderPacientes,
  renderRastreamento: renderRastreamentoVivo,
  renderSync,
  renderDebug,
};
