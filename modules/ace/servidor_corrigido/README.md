# Servidor local — ACE Territorial + LogiSaúde

Servidor Node.js unificado para testes do app ACE, plataforma web LogiSaúde e Driver App.

## Instalação

```bash
npm install --prefix servidor_corrigido
```

## Executar

```bash
node servidor_corrigido/server.js
```

Porta padrão: **3000** (`PORT` e `HOST` via variáveis de ambiente).

## URLs principais

| URL | Descrição |
|-----|-----------|
| `/` | Portal (ACE + LogiSaúde) |
| `/painel-ace` | Redireciona para painel driver ACE |
| `/painel` | Painel de sync do driver (legado) |
| `/logisaude` | Dashboard LogiSaúde |
| `/api/status` | Status ACE (inalterado) |
| `/api/logisaude/dashboard` | Métricas LogiSaúde |
| `/api/driver/events` | Eventos do app motorista |

## Estrutura

```
servidor_corrigido/
├── server.js
├── data/logisaude-data.json
├── lib/
├── routes/
├── views/
└── public/logisaude.css
```

Dados LogiSaúde persistem em `data/logisaude-data.json`. Driver e ACE usam memória volátil.
