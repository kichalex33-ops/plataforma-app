import 'visita_pe_model.dart';

class RelatorioPEItemModel {
  final String peNome;
  final String peEndereco;
  final String peTipo;
  final VisitaPEModel visita;

  RelatorioPEItemModel({
    required this.peNome,
    required this.peEndereco,
    required this.peTipo,
    required this.visita,
  });
}
