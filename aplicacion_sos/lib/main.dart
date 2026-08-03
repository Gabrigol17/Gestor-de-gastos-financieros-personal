import 'package:flutter/material.dart';
import 'package:aplicacion_sos/View_Inicio.dart';
void main(){
  runApp(Myapp());
}

class Myapp extends StatelessWidget {

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gestor Financiero",
      home: ViewInicio()
    );
  }


}