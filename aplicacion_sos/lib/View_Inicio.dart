import 'package:flutter/material.dart';

class ViewInicio extends StatelessWidget{
  const ViewInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Gestor financiero", style: TextStyle(color: Colors.white),)
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ElevatedButton(onPressed: null, child: Text("Puto"))],
          )
          )
          );  
  }

}