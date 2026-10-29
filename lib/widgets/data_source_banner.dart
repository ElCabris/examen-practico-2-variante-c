import 'package:flutter/material.dart';

class LocalDataNotice extends StatelessWidget {
  const LocalDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.cloud_off),
        title: Text('Mostrando datos locales'),
        subtitle: Text(
          'No se pudo conectar con Firestore. Se muestra el último estado '
          'guardado. Desliza hacia abajo para reintentar.',
        ),
      ),
    );
  }
}
