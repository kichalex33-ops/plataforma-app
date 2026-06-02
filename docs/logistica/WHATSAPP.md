# WhatsApp Operacional

## Objetivo

Preparar uma estrutura futura para comunicação operacional sem disparar mensagens reais nesta fase.

## Casos de Uso

- Aviso ao motorista.
- Aviso à unidade de saúde.
- Confirmação de passageiro.
- Alerta para gestor.
- Comunicação de ocorrência.

## Implementação Atual

Arquivo:

- `modules/logistica/lib/core/logistica/integracoes/logistica_external_integration.dart`

Classes:

- `LogisticaWhatsappUseCase`
- `LogisticaWhatsappSimulationMessage`
- `LogisticaWhatsappSimulationService`

## Regra Atual

O WhatsApp é somente simulado:

- `simulado = true`;
- `disparoRealExecutado = false`;
- mensagem fica em log interno.

## Produção

Para disparo real será necessário:

- provedor oficial ou API homologada;
- consentimento e regras LGPD;
- templates aprovados quando aplicável;
- auditoria por mensagem;
- fallback quando sem internet.
