import 'package:flutter/material.dart';
import 'package:internal_request_app/presentation/widgets/page_placeholder_content.dart';

class WorkBoardPage extends StatelessWidget {
  const WorkBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholderContent(
      title: 'Tablero de trabajo',
      description: 'Aquí podrás consultar el trabajo asignado.',
    );
  }
}
