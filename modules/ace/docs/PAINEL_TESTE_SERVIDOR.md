# Painel de Teste do Servidor LogiSaude

Este painel valida o fluxo inicial:

```text
Driver App -> Backend local -> Painel de teste
```

Ele nao e o painel operacional definitivo. Nao possui autenticacao, banco persistente, permissoes ou auditoria completa.

## Como rodar

Na raiz do projeto:

```bash
npm install --prefix servidor_corrigido
node servidor_corrigido/server.js
```

Se as dependencias `express` e `cors` ainda nao estiverem instaladas, o servidor possui um fallback HTTP minimo para testes locais.

Servidor padrao:

```text
http://localhost:3000
```

Portal inicial:

```text
http://localhost:3000/
```

Painel ACE (driver):

```text
http://localhost:3000/painel-ace
```

Plataforma LogiSaúde:

```text
http://localhost:3000/logisaude
```

Painel driver legado:

```text
http://localhost:3000/painel
```

Status:

```text
http://localhost:3000/api/status
```

## Endpoints

### Eventos do motorista

```text
POST /api/driver/events
GET /api/driver/events
```

Payload exemplo:

```json
{
  "id": "evento-001",
  "viagemId": "viagem-001",
  "motoristaId": "motorista-001",
  "municipioId": "municipio-001",
  "tipo": "viagem_iniciada",
  "payloadJson": "{\"origem\":\"UBS Centro\"}",
  "syncStatus": "pending"
}
```

### Localizacoes

```text
POST /api/driver/locations
GET /api/driver/locations
```

Payload exemplo:

```json
{
  "viagemId": "viagem-001",
  "motoristaId": "motorista-001",
  "latitude": -29.684,
  "longitude": -51.461,
  "velocidade": 42
}
```

### Status de viagem

```text
POST /api/driver/trips/status
GET /api/driver/trips/status
```

Payload exemplo:

```json
{
  "viagemId": "viagem-001",
  "motoristaId": "motorista-001",
  "status": "em_andamento"
}
```

## Testes com curl

Status:

```bash
curl http://localhost:3000/api/status
```

Enviar evento:

```bash
curl -X POST http://localhost:3000/api/driver/events \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"evento-001\",\"viagemId\":\"viagem-001\",\"motoristaId\":\"motorista-001\",\"municipioId\":\"local\",\"tipo\":\"viagem_iniciada\",\"payloadJson\":\"{}\",\"syncStatus\":\"pending\"}"
```

Enviar localizacao:

```bash
curl -X POST http://localhost:3000/api/driver/locations \
  -H "Content-Type: application/json" \
  -d "{\"viagemId\":\"viagem-001\",\"motoristaId\":\"motorista-001\",\"latitude\":-29.684,\"longitude\":-51.461}"
```

Enviar status:

```bash
curl -X POST http://localhost:3000/api/driver/trips/status \
  -H "Content-Type: application/json" \
  -d "{\"viagemId\":\"viagem-001\",\"motoristaId\":\"motorista-001\",\"status\":\"em_andamento\"}"
```

Listar dados:

```bash
curl http://localhost:3000/api/driver/events
curl http://localhost:3000/api/driver/locations
curl http://localhost:3000/api/driver/trips/status
```

## Teste com o app

1. Rode o servidor local.
2. Configure o app para usar `http://localhost:3000` quando estiver no mesmo ambiente, ou o IP da maquina na rede local quando estiver no celular.
3. Gere eventos no Driver App.
4. Abra `http://localhost:3000/painel`.
5. Clique em `Atualizar` para ver eventos, localizacoes e status recebidos.

Os dados ficam em memoria e sao perdidos ao reiniciar o processo Node.js.
