class VisitaDomiciliarModel {
  final int? id;
  final int? rgQuarteiraoId;
  final String rgQuarteiraoCodigo;
  final String endereco;
  final String numero;
  final String complemento;
  final String municipio;
  final String agente;
  final String entradaEm;
  final String saidaEm;
  final String situacao;
  final bool focoPositivo;
  final int quantidadeTubitos;
  final String observacoes;
  final double entradaLatitude;
  final double entradaLongitude;
  final double saidaLatitude;
  final double saidaLongitude;
  final List<int> tubitos;

  const VisitaDomiciliarModel({
    this.id,
    this.rgQuarteiraoId,
    required this.rgQuarteiraoCodigo,
    required this.endereco,
    required this.numero,
    required this.complemento,
    required this.municipio,
    required this.agente,
    required this.entradaEm,
    required this.saidaEm,
    required this.situacao,
    required this.focoPositivo,
    required this.quantidadeTubitos,
    required this.observacoes,
    required this.entradaLatitude,
    required this.entradaLongitude,
    required this.saidaLatitude,
    required this.saidaLongitude,
    this.tubitos = const [],
  });

  factory VisitaDomiciliarModel.fromMap(
    Map<String, dynamic> map, {
    List<int> tubitos = const [],
  }) {
    return VisitaDomiciliarModel(
      id: map['id'],
      rgQuarteiraoId: map['rg_quarteirao_id'],
      rgQuarteiraoCodigo: map['rg_quarteirao_codigo'] ?? '',
      endereco: map['endereco'] ?? '',
      numero: map['numero'] ?? '',
      complemento: map['complemento'] ?? '',
      municipio: map['municipio'] ?? '',
      agente: map['agente'] ?? '',
      entradaEm: map['entrada_em'] ?? '',
      saidaEm: map['saida_em'] ?? '',
      situacao: map['situacao'] ?? '',
      focoPositivo: map['foco_positivo'] == 1,
      quantidadeTubitos: map['quantidade_tubitos'] ?? 0,
      observacoes: map['observacoes'] ?? '',
      entradaLatitude: (map['entrada_latitude'] as num?)?.toDouble() ?? 0,
      entradaLongitude: (map['entrada_longitude'] as num?)?.toDouble() ?? 0,
      saidaLatitude: (map['saida_latitude'] as num?)?.toDouble() ?? 0,
      saidaLongitude: (map['saida_longitude'] as num?)?.toDouble() ?? 0,
      tubitos: tubitos,
    );
  }
}
