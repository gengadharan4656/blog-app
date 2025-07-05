import 'package:flutter/material.dart';
void main(){
  runApp(chocker());
}
class chocker extends StatefulWidget{
  @override
  _chockerState createState() => _chockerState();
}

class _chockerState extends State<chocker>{
  @override
  String displayText="dharan";
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title:Text("hi to bye")
        ),
        body: Column(
          children: [
            Text(displayText),
            MaterialButton(onPressed:() {
              setState(() {
                if (displayText=="dharan"){
                  displayText="king";
                }
                else{
                  displayText="dharan";
                }
              });
            },
              child: Text("clicked"),
              color: Colors.blue,
            )
          ],
        ),
      ),
    );
  }
}