import 'package:flutter/material.dart';
import './yolo.dart';

void main() {
  runApp(const MyYolo());
}

class MyYolo extends StatelessWidget {
  const MyYolo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(builder: (context) {
            return FloatingActionButton(onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const YoloSample()),
              );
            });
          }),
        ),
      ),
    );
  }
}
