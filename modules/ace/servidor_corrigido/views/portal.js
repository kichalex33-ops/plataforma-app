function renderPortal() {
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Portal — ACE Territorial & LogiSaúde</title>
  <link rel="stylesheet" href="/logisaude.css">
</head>
<body class="portal-body">
  <div>
    <h1 style="text-align:center;margin-bottom:8px;">Plataforma Municipal de Saúde</h1>
    <p style="text-align:center;color:#5f7a82;margin-bottom:28px;">
      Escolha o módulo para continuar. Ambiente local de testes (sem autenticação).
    </p>
    <div class="portal-grid">
      <article class="portal-card ace">
        <h2>ACE Territorial</h2>
        <p>Controle de endemias, visitas, BTI, ovitrampas e sincronização do app ACE.</p>
        <a class="btn btn-ace" href="/painel-ace">Abrir painel ACE</a>
      </article>
      <article class="portal-card logisaude">
        <h2>LogiSaúde</h2>
        <p>Operação logística, viagens, motoristas, veículos, pacientes e rastreamento.</p>
        <a class="btn btn-ls" href="/logisaude">Abrir LogiSaúde</a>
      </article>
    </div>
  </div>
</body>
</html>`;
}

module.exports = { renderPortal };
