import 'package:flutter/material.dart';

class ShowSentImage extends StatelessWidget {
  final String imagePath;

  const ShowSentImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sent Image'),
      ),
      body: Dismissible(
        key: Key(imagePath),
        direction: DismissDirection.down,
        onDismissed: (direction) {
          Navigator.of(context).pop();
        },
        child: Center(
          child: Image.network(imagePath),
        ),
      ),
    );
  }
}
