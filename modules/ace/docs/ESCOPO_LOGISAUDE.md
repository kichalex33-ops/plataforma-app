# Escopo LogiSaude

## Objetivo

O LogiSaude e uma plataforma municipal de logistica em saude, focada em transporte sanitario, passageiros, pacientes, veiculos, motoristas, rastreio GPS, sincronizacao offline-first e controle operacional.

## Dentro do escopo

- Cadastro e acompanhamento de viagens.
- Estados formais da viagem: `rascunho`, `agendada`, `em_andamento`, `concluida`, `cancelada`.
- Motoristas e veiculos.
- Pacientes como cadastro de pessoas.
- Passageiros como participacao de uma pessoa em uma viagem.
- Rastreio GPS real ou simulado.
- Central de sincronizacao.
- Auditoria operacional.
- Operacao offline-first.

## Fora do escopo

- Vigilancia endemica.
- Pontos estrategicos de endemias.
- BTI.
- Ovitrampas.
- LIRA/LIA.
- Tubitos.
- Focos epidemiologicos.
- Farmacia.

## Regras

- Nenhum registro operacional depende da internet para existir.
- Toda escrita local relevante deve entrar na `sync_queue`.
- Passageiro sempre pertence a uma viagem.
- Rastreio simulado deve ser indicado como simulado na UI e no banco.
- Rastreio real deve usar `origem_dado = gps_real`.
