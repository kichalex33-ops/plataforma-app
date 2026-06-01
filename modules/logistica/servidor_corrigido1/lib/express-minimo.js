/** Fallback HTTP mínimo quando express não está instalado. */

function criarExpressMinimo() {
  const http = require('http');
  const rotas = [];

  function app() {}

  app.use = () => {};

  app.get = (path, handler) => {
    rotas.push({ method: 'GET', path, handler });
  };

  app.post = (path, handler) => {
    rotas.push({ method: 'POST', path, handler });
  };

  app.listen = (port, host, callback) => {
    const server = http.createServer((req, res) => {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

      if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
      }

      const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
      const rota = rotas.find(
        (item) => item.method === req.method && item.path === url.pathname,
      );

      res.status = (code) => {
        res.statusCode = code;
        return res;
      };
      res.json = (body) => {
        res.setHeader('Content-Type', 'application/json; charset=utf-8');
        res.end(JSON.stringify(body));
      };
      res.type = (type) => {
        res.setHeader('Content-Type', `${type}; charset=utf-8`);
        return res;
      };
      res.send = (body) => {
        res.end(body);
      };
      res.redirect = (location) => {
        res.writeHead(302, { Location: location });
        res.end();
      };

      if (!rota) {
        res.status(404).json({ erro: 'Rota nao encontrada' });
        return;
      }

      let raw = '';
      req.on('data', (chunk) => {
        raw += chunk;
      });
      req.on('end', () => {
        try {
          req.body = raw ? JSON.parse(raw) : {};
        } catch (error) {
          req.body = {};
        }
        req.params = {};
        rota.handler(req, res);
      });
    });

    return server.listen(port, host, callback);
  };

  return app;
}

module.exports = criarExpressMinimo;
module.exports.json = () => (_req, _res, next) => next && next();
module.exports.static = () => (_req, _res, next) => next && next();
