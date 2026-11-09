import 'package:flutter/material.dart';
import 'package:internal_request_app/presentation/widgets/page_placeholder_content.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholderContent(
      title: 'Mis solicitudes',
      description: 'Aquí podrás consultar tus solicitudes.',
    );
  }
}
