// ACE Territorial — armazenamento em memória (sem alterar contratos existentes).

const perfis_ace = [];
const pontos_estrategicos = [];
const visitas_pe = [];
const visitas_domiciliares = [];
const bti = [];
const ovitrampas = [];
const ovitrampa_checagens = [];
const coletas_larvarias = [];
const casos_dengue = [];
const esporotricose = [];
const quarteiroes = [];
const atividades_quarteirao = [];
const exclusoes_log = [];
const alertas_emergencia = [];
const localidades = [];
const setores_operacionais = [];
const quarteiroes_operacionais = [];
const atribuicoes_setor = [];
const progresso_quarteirao = [];
const auditoria_eventos = [];
const transportes_motoristas = [];
const transportes_veiculos = [];
const transportes_viagens = [];
const transportes_passageiros = [];
const pacientes = [];
const rastreamento_viagem = [];
const mapas_camadas = [];

let ultimo_tubito = 0;

function proximoId(lista) {
  if (!lista.length) return 1;
  return Math.max(...lista.map((item) => Number(item.id) || 0)) + 1;
}

function montarRegistro(lista, dados) {
  const agora = new Date();

  return {
    id: dados.id || proximoId(lista),
    municipio: dados.municipio || null,
    ace_responsavel: dados.ace_responsavel || dados.agente || null,
    latitude: dados.latitude ?? null,
    longitude: dados.longitude ?? null,
    data: dados.data || dados.data_visita || agora.toISOString().slice(0, 10),
    hora: dados.hora || agora.toTimeString().slice(0, 5),
    observacoes: dados.observacoes || null,
    status: dados.status || dados.situacao || null,
    foto_path: dados.foto_path || null,
    tipo: dados.tipo || null,
    origem: dados.origem || 'app_flutter',
    sincronizado_em: dados.sincronizado_em || agora.toISOString(),
    ...dados,
  };
}

function contarPorStatus(lista, status) {
  return lista.filter((item) => item.status === status).length;
}

function ehFocoPositivo(item) {
  return (
    item.foco_positivo === true ||
    item.foco_positivo === 1 ||
    item.focoPositivo === true ||
    item.resultado === 'Positiva' ||
    item.resultado === 'Positivo' ||
    item.status === 'Positiva' ||
    item.status === 'Positivo' ||
    item.status === 'Com foco'
  );
}

module.exports = {
  perfis_ace,
  pontos_estrategicos,
  visitas_pe,
  visitas_domiciliares,
  bti,
  ovitrampas,
  ovitrampa_checagens,
  coletas_larvarias,
  casos_dengue,
  esporotricose,
  quarteiroes,
  atividades_quarteirao,
  exclusoes_log,
  alertas_emergencia,
  localidades,
  setores_operacionais,
  quarteiroes_operacionais,
  atribuicoes_setor,
  progresso_quarteirao,
  auditoria_eventos,
  transportes_motoristas,
  transportes_veiculos,
  transportes_viagens,
  transportes_passageiros,
  pacientes,
  rastreamento_viagem,
  mapas_camadas,
  get ultimo_tubito() {
    return ultimo_tubito;
  },
  set ultimo_tubito(valor) {
    ultimo_tubito = valor;
  },
  proximoId,
  montarRegistro,
  contarPorStatus,
  ehFocoPositivo,
};
