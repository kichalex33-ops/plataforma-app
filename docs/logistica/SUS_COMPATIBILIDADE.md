# Compatibilidade SUS

## Objetivo

Preparar dados compatíveis para auditoria de transporte sanitário, sem integração oficial com sistemas SUS nesta etapa.

## Implementação Atual

Arquivo:

- `modules/logistica/lib/core/logistica/integracoes/logistica_sus_compatibility.dart`

Classes:

- `LogisticaSusAuditRecord`
- `LogisticaSusCompatibility`

## Campos Obrigatórios

- CNS.
- CPF.
- Paciente.
- Unidade de saúde.
- Procedimento ou consulta.
- Data.
- Destino.
- Comprovante.
- Presença.
- Acompanhante quando houver.

## Validação

A validação retorna a lista de campos pendentes. O objetivo é apoiar auditoria interna e preparar payload futuro.

## Limites

Não há integração oficial com SUS, TFD, CNES ou sistemas estaduais. Qualquer integração real exige autorização formal, contrato técnico e revisão jurídica.
