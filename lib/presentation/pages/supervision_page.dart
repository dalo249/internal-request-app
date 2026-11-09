import 'package:flutter/material.dart';
import 'package:internal_request_app/presentation/widgets/page_placeholder_content.dart';

class SupervisionPage extends StatelessWidget {
  const SupervisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholderContent(
      title: 'Bandeja de supervisión',
      description: 'Aquí podrás revisar las solicitudes pendientes.',
    );
  }
}
