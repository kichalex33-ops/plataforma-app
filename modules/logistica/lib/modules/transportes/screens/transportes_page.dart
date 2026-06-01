import 'package:flutter/material.dart';

import '../../../motorista/minhas_viagens/minhas_viagens_page.dart';

class TransportesPage extends StatelessWidget {
  final bool embed;

  const TransportesPage({super.key, this.embed = false});

  @override
  Widget build(BuildContext context) => MinhasViagensPage(embed: embed);
}
