# Servidor local LogiSaude

Servidor Node.js local para testes da plataforma LogiSaude e do Driver App.

## Como rodar

```bash
npm install
npm start
```

Servidor padrao: `http://10.0.0.3:3000`

## Rotas principais

| Rota | Uso |
| --- | --- |
| `/` | Portal LogiSaude |
| `/logisaude` | Painel web local |
| `/api/status` | Status do servidor |
| `/api/driver/events` | Eventos enviados pelo app motorista |
| `/api/driver/locations` | Localizacoes enviadas pelo app motorista |
| `/api/driver/trips/status` | Status de viagens enviado pelo app motorista |
| `/api/logisaude/dashboard` | Resumo operacional do painel |

Dados da plataforma sao persistidos em `data/logisaude-data.json`. Eventos do Driver App usam memoria durante a execucao do servidor.
