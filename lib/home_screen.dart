import 'dart:convert';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class HomeScreen extends StatefulWidget{
  @override
  _HomeScreenState createState()=> _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final GlobalKey<AnimatedListState> _ListKey=GlobalKey();
  List<String> _data=[];


  TextEditingController queryController=TextEditingController();
  final BOT_URL = Uri.parse("https://chatbotliqahona.herokuapp.com/chat");
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Text(
          "chatBot",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: <Widget>[
          AnimatedList(
              key: _ListKey,
              initialItemCount: _data.length,
              itemBuilder: (BuildContext context,int index,Animation<double> animation){
                return buildItem(_data[index],animation,index);
              }),
          Align(
            alignment: Alignment.bottomCenter,
            child: ColorFiltered(
                colorFilter: ColorFilter.linearToSrgbGamma(),
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(left: 20,right: 20),
                  child: TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.message,
                        color: Colors.blue,
                      ),
                      hintText: "Hello Bot",
                      fillColor: Colors.white,
                    ),
                    controller: queryController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (msg){
                      this.getResponse();
                    },

                  ),
                ),
              ),
            )


          )
        ],
      ),
    );
  }

  //response
void getResponse(){
    if(queryController.text.length>0){
      this.insertSingleItem(queryController.text);
      var client = getClient();
      try{
        client.post(
          BOT_URL,
          body: {"message":queryController.text},
        ).then((responses){
          print(responses.body);
          //Map<String,dynamic> data=jsonDecode(responses.body);
          insertSingleItem(responses.body+"<chat>");
        });
      }finally{
        client.close();
        queryController.clear();
      }
    }
}

void insertSingleItem(String message){
    _data.add(message);
    _ListKey.currentState!.insertItem(_data.length - 1);
}
http.Client getClient(){
    return http.Client();
}
}
Widget buildItem(String item,Animation<double> animation,int index){
  bool mine=item.endsWith("<chat>");
  return SizeTransition(
      sizeFactor: animation,
      child: Padding(
        padding: EdgeInsets.only(top: 10),
        child: Container(
          alignment: mine ? Alignment.topLeft: Alignment.topRight,
          child: Bubble(
            child: Text(
              item.replaceAll("<chat>", ""),
              style: TextStyle(
                color: mine ? Colors.white: Colors.black
              ),
            ),
            color: mine ? Colors.blue:Colors.grey[200],
            padding: BubbleEdges.all(10),
          ),
        ),
      ),
  );
}