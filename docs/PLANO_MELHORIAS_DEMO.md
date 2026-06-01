# Plano de Melhorias da Demo

## 1. Análise técnica do estado atual

### O que está funcionando

- A demo abre em uma tela de login própria da Andrade Gestão em Saúde.
- O login demo com usuário `Alex` e senha `1234` libera o acesso.
- Após o login, a tela de seleção exibe os módulos `Logística` e `ACE`.
- O botão `Logística` abre o módulo reaproveitado do LogiSaúde.
- O botão `ACE` abre o módulo reaproveitado do ACE.
- A entrada da demo possui identidade institucional própria, separada dos módulos internos.

### O que está preservado dos apps originais

- Os layouts internos dos módulos foram mantidos com o mínimo de adaptação.
- O código de Logística está reaproveitado em `modules/logistica`.
- O código de ACE está reaproveitado em `modules/ace`.
- Os projetos originais fora da pasta da demo não foram alterados.
- A navegação principal da demo apenas encapsula os módulos preservados.

### O que é apenas casca de demo

- A autenticação é fixa e local, sem consulta a servidor.
- A seleção de módulos não usa permissões reais.
- A integração entre módulos ocorre por navegação, não por base de dados compartilhada.
- A identidade Andrade está concentrada na entrada e seleção.
- Os dados operacionais continuam sendo tratados dentro de cada módulo reaproveitado.

### O que ainda não é unificação real

- Ainda não existe banco único entre Logística e ACE.
- Ainda não existe sessão centralizada com perfis, permissões e município.
- Ainda não existe sincronização entre app e painel.
- Ainda não existe contrato ativo com backend.
- Ainda não existe módulo ACS dentro da demo.
- Ainda não existe IA operacional integrada.
- Ainda não há integração funcional entre registros de Logística e ACE.

## 2. Pontos positivos

- Login demo funcional.
- Seleção entre Logística e ACE.
- Preservação dos layouts internos.
- Identidade Andrade aplicada na entrada.
- Projetos originais preservados.
- Estrutura simples para testes rápidos em APK.
- Baixo risco de regressão nos módulos internos nesta fase.

## 3. Fragilidades atuais

- Ainda não há autenticação real.
- Ainda não há permissões reais por perfil.
- Ainda não há banco único.
- Ainda não há sincronização com servidor.
- Ainda não há ACS.
- Ainda não há integração real entre Logística e ACE.
- Módulos ainda dependem de reaproveitamento, cópia ou wrappers.
- Nomenclatura e acentuação precisam permanecer padronizadas em telas e documentação.
- O tratamento de erro entre módulos ainda é básico.
- O fluxo de saída, troca de módulo e retorno pode ser refinado.

## 4. Melhorias por etapas

### Etapa 1 — Correções de demo

- Objetivo: manter a demo estável, corrigida e pronta para apresentação.
- Arquivos envolvidos:
  - `README.md`
  - `docs/RELATORIO_DEMO_UNIFICADA.md`
  - `docs/PLANO_MELHORIAS_DEMO.md`
  - `lib/main.dart`
  - `lib/screens/login_demo_page.dart`
  - `lib/screens/module_selector_page.dart`
  - `lib/modules/logistica/logistica_module_page.dart`
  - `lib/modules/ace/ace_module_page.dart`
- Ações:
  - Padronizar nomes: Logística e ACE.
  - Corrigir acentuação.
  - Melhorar README.
  - Melhorar relatório.
  - Confirmar build limpo.
- Risco: baixo.
- Esforço estimado: baixo.
- Prioridade: alta.

### Etapa 2 — Qualidade visual da entrada

- Objetivo: deixar login e seleção mais institucionais sem alterar os módulos internos.
- Arquivos envolvidos:
  - `lib/screens/login_demo_page.dart`
  - `lib/screens/module_selector_page.dart`
- Ações:
  - Melhorar tela de login.
  - Melhorar tela de seleção.
  - Adicionar cards mais institucionais.
  - Adicionar descrição curta de cada módulo.
  - Manter identidade Andrade apenas na entrada.
- Risco: baixo.
- Esforço estimado: baixo a médio.
- Prioridade: média.

### Etapa 3 — Estabilização dos módulos preservados

- Objetivo: garantir que cada módulo continue funcionando sem derrubar a demo inteira.
- Arquivos envolvidos:
  - `lib/modules/logistica/logistica_module_page.dart`
  - `lib/modules/ace/ace_module_page.dart`
  - `modules/logistica`
  - `modules/ace`
- Ações:
  - Garantir botão voltar ou sair.
  - Garantir navegação segura.
  - Isolar erros de um módulo para não quebrar o outro.
  - Documentar dependências reaproveitadas.
- Risco: médio, pois toca pontos de integração com módulos copiados.
- Esforço estimado: médio.
- Prioridade: alta após a demo básica.

### Etapa 4 — Logística operacional

- Objetivo: evoluir o módulo Logística como fluxo profissional de transporte em saúde.
- Arquivos envolvidos:
  - `modules/logistica`
  - `lib/modules/logistica/logistica_module_page.dart`
  - futura documentação operacional em `docs/`
- Ações:
  - Km inicial e final.
  - Abastecimentos.
  - Checklists.
  - Ocorrências.
  - Histórico.
  - Indicadores básicos.
- Risco: médio a alto, dependendo do nível de alteração no app reaproveitado.
- Esforço estimado: médio a alto.
- Prioridade: alta.

### Etapa 5 — ACE operacional

- Objetivo: estabilizar o ACE para uso territorial preservando a base visual e funcional original.
- Arquivos envolvidos:
  - `modules/ace`
  - `lib/modules/ace/ace_module_page.dart`
  - futura documentação operacional em `docs/`
- Ações:
  - PE.
  - Visitas.
  - Focos.
  - BTI.
  - Ovitrampas.
  - LIRA/LIA.
  - Relatórios.
  - Mapa.
- Risco: médio a alto, principalmente em telas com formulários, mapas e persistência local.
- Esforço estimado: médio a alto.
- Prioridade: alta depois de Logística.

### Etapa 6 — Unificação real futura

- Objetivo: transformar a demo em app único real, com autenticação, permissões e dados integrados.
- Arquivos envolvidos:
  - `lib/`
  - `modules/logistica`
  - `modules/ace`
  - futura camada `core/`
  - futura documentação de API em `docs/`
- Ações:
  - Login real.
  - Perfis e permissões.
  - Banco único.
  - Offline-first.
  - Sincronização 4G/Wi-Fi.
  - API futura.
  - ACS.
  - IA operacional.
- Risco: alto, pois muda arquitetura, dados, autenticação e ciclo de sincronização.
- Esforço estimado: alto.
- Prioridade: futura, após a demo e os módulos principais estarem estáveis.

## 5. Ordem recomendada

Priorizar:

1. Demo estável.
2. Logística.
3. ACE.
4. ACS.
5. Indicadores.
6. Sincronização.
7. IA.
