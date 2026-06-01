function renderPortal() {
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Portal LogiSaude</title>
  <link rel="stylesheet" href="/logisaude.css">
</head>
<body class="portal-body">
  <main class="portal-single">
    <h1>LogiSaude Logistica Municipal</h1>
    <p>Ambiente local de testes para viagens, motoristas, veiculos, pacientes e rastreamento.</p>
    <a class="btn btn-ls" href="/logisaude">Abrir painel LogiSaude</a>
  </main>
</body>
</html>`;
}

module.exports = { renderPortal };
