// Driver App — eventos, localizações e status em memória.

const driver_events = [];
const driver_locations = [];
const driver_trips_status = [];
const driver_trips_cache = [];

let driver_ultimo_recebimento = null;

function registrarDriver(lista, dados, tipoRegistro) {
  const recebidoEm = new Date().toISOString();
  driver_ultimo_recebimento = recebidoEm;

  const registro = {
    id: dados.id || `${tipoRegistro}-${Date.now()}-${lista.length + 1}`,
    received_at: recebidoEm,
    ...dados,
  };

  lista.push(registro);
  return registro;
}

function respostaDriver(lista) {
  return {
    total: lista.length,
    lastReceivedAt: driver_ultimo_recebimento,
    items: lista,
  };
}

module.exports = {
  driver_events,
  driver_locations,
  driver_trips_status,
  driver_trips_cache,
  get driver_ultimo_recebimento() {
    return driver_ultimo_recebimento;
  },
  registrarDriver,
  respostaDriver,
};
