/**
 * Servidor local unificado:
 * - ACE Territorial (APIs e painel existentes)
 * - LogiSaúde (plataforma web + APIs de teste)
 * - Driver App (eventos, localizações, viagens)
 */

const path = require('path');

let express;
let cors;

try {
  express = require('express');
  cors = require('cors');
} catch (error) {
  console.warn('Express/CORS nao encontrados. Usando servidor HTTP minimo de teste.');
  express = require('./lib/express-minimo');
  cors = () => (_req, _res, next) => next && next();
}

const driverStore = require('./lib/driver-store');
const { renderPortal } = require('./views/portal');
const { registerAceRoutes } = require('./routes/ace.routes');
const { registerDriverRoutes } = require('./routes/driver.routes');
const { registerLogisaudeRoutes } = require('./routes/logisaude.routes');

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const HOST = process.env.HOST || '0.0.0.0';

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// Portal inicial — ACE + LogiSaúde
app.get('/', (req, res) => {
  res.type('html').send(renderPortal());
});

// =============================================================================
// Módulos de rotas
// =============================================================================
registerAceRoutes(app, driverStore);
registerDriverRoutes(app, driverStore, require('./lib/logisaude-store'));
registerLogisaudeRoutes(app, driverStore);

app.listen(PORT, HOST, () => {
  console.log(`Servidor rodando em http://${HOST === '0.0.0.0' ? 'localhost' : HOST}:${PORT}`);
  console.log('  Portal:        /');
  console.log('  ACE painel:    /painel-ace  (→ /painel)');
  console.log('  LogiSaúde:     /logisaude');
  console.log('  API status:    /api/status');
  console.log('  API LogiSaúde: /api/logisaude/dashboard');
});
