const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, '../data/logisaude-data.json');

let dados = carregarDados();

function carregarDados() {
  try {
    const bruto = fs.readFileSync(DATA_FILE, 'utf8');
    return JSON.parse(bruto);
  } catch (error) {
    console.warn('[LogiSaude] Nao foi possivel carregar JSON inicial:', error.message);
    return {
      municipio: 'Poço das Antas',
      motoristas: [],
      veiculos: [],
      pacientes: [],
      passageiros: [],
      viagens: [],
      falhas_sync: [],
    };
  }
}

function salvarDados() {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(dados, null, 2), 'utf8');
  } catch (error) {
    console.warn('[LogiSaude] Falha ao salvar JSON:', error.message);
  }
}

function proximoId(prefixo, lista) {
  const numeros = lista
    .map((item) => String(item.id || ''))
    .filter((id) => id.startsWith(prefixo))
    .map((id) => Number(id.replace(/\D/g, '')) || 0);
  const proximo = numeros.length ? Math.max(...numeros) + 1 : 1;
  return `${prefixo}${String(proximo).padStart(3, '0')}`;
}

function getDados() {
  return dados;
}

function listarViagens() {
  return dados.viagens;
}

function listarMotoristas() {
  return dados.motoristas;
}

function listarVeiculos() {
  return dados.veiculos;
}

function listarPacientes() {
  return dados.pacientes;
}

function listarPassageiros() {
  return dados.passageiros;
}

function encontrarViagem(id) {
  return dados.viagens.find((item) => item.id === id);
}

function adicionarMotorista(body) {
  const registro = {
    id: body.id || proximoId('mot-', dados.motoristas),
    nome: body.nome || 'Motorista sem nome',
    municipio: body.municipio || dados.municipio,
    telefone: body.telefone || null,
    status: body.status || 'ativo',
    created_at: new Date().toISOString(),
  };
  dados.motoristas.push(registro);
  salvarDados();
  return registro;
}

function adicionarVeiculo(body) {
  const registro = {
    id: body.id || proximoId('veic-', dados.veiculos),
    nome: body.nome || 'Veículo sem nome',
    placa: body.placa || null,
    tipo: body.tipo || 'van',
    status: body.status || 'disponivel',
    created_at: new Date().toISOString(),
  };
  dados.veiculos.push(registro);
  salvarDados();
  return registro;
}

function adicionarPaciente(body) {
  const registro = {
    id: body.id || proximoId('pac-', dados.pacientes),
    nome: body.nome || 'Paciente sem nome',
    motivo: body.motivo || null,
    municipio: body.municipio || dados.municipio,
    created_at: new Date().toISOString(),
  };
  dados.pacientes.push(registro);
  salvarDados();
  return registro;
}

function adicionarPassageiro(body) {
  const registro = {
    id: body.id || proximoId('pas-', dados.passageiros),
    paciente_id: body.paciente_id || null,
    nome: body.nome || 'Passageiro sem nome',
    motivo: body.motivo || null,
    created_at: new Date().toISOString(),
  };
  dados.passageiros.push(registro);
  salvarDados();
  return registro;
}

function adicionarViagem(body) {
  const registro = {
    id: body.id || proximoId('viagem-', dados.viagens),
    origem: body.origem || 'Origem',
    destino: body.destino || 'Destino',
    status: body.status || 'programada',
    motorista_id: body.motorista_id || null,
    veiculo_id: body.veiculo_id || null,
    passageiro_ids: body.passageiro_ids || [],
    municipio: body.municipio || dados.municipio,
    data_hora_saida: body.data_hora_saida || new Date().toISOString(),
    created_at: new Date().toISOString(),
  };
  dados.viagens.push(registro);
  salvarDados();
  return registro;
}

function atualizarStatusViagem(id, status) {
  const viagem = encontrarViagem(id);
  if (!viagem) return null;
  viagem.status = status;
  viagem.updated_at = new Date().toISOString();
  salvarDados();
  return viagem;
}

function registrarFalhaSync(mensagem) {
  const registro = {
    id: `falha-${Date.now()}`,
    mensagem,
    created_at: new Date().toISOString(),
  };
  dados.falhas_sync.push(registro);
  salvarDados();
  return registro;
}

function montarDashboard(driverStore) {
  const hoje = new Date().toISOString().slice(0, 10);
  const viagensHoje = dados.viagens.filter((v) =>
    String(v.data_hora_saida || '').startsWith(hoje),
  );
  const emAndamento = dados.viagens.filter((v) => v.status === 'em_andamento');
  const motoristasAtivos = dados.motoristas.filter((m) => m.status === 'ativo');
  const veiculosDisponiveis = dados.veiculos.filter(
    (v) => v.status === 'disponivel',
  );

  return {
    municipio: dados.municipio,
    viagens_do_dia: viagensHoje.length,
    viagens_em_andamento: emAndamento.length,
    pacientes_passageiros: dados.pacientes.length + dados.passageiros.length,
    motoristas_ativos: motoristasAtivos.length,
    veiculos_disponiveis: veiculosDisponiveis.length,
    eventos_recebidos: driverStore.driver_events.length,
    localizacoes_recebidas: driverStore.driver_locations.length,
    pendencias_sync: dados.falhas_sync.length,
    total_viagens: dados.viagens.length,
    data_hora: new Date().toISOString(),
  };
}

function viagensParaDriverApp() {
  return dados.viagens.map((viagem) => ({
    id: viagem.id,
    origem: viagem.origem,
    destino: viagem.destino,
    status: viagem.status,
    motorista_id: viagem.motorista_id,
    veiculo_id: viagem.veiculo_id,
    municipio_id: viagem.municipio,
    data_hora_saida: viagem.data_hora_saida,
    passageiro_ids: viagem.passageiro_ids || [],
  }));
}

module.exports = {
  getDados,
  listarViagens,
  listarMotoristas,
  listarVeiculos,
  listarPacientes,
  listarPassageiros,
  encontrarViagem,
  adicionarMotorista,
  adicionarVeiculo,
  adicionarPaciente,
  adicionarPassageiro,
  adicionarViagem,
  atualizarStatusViagem,
  registrarFalhaSync,
  montarDashboard,
  viagensParaDriverApp,
  salvarDados,
};
