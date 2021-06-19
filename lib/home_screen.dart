import 'dart:async';
import 'dart:convert';
import 'package:chatbotapp/models/Message.dart';
import 'package:chatbotapp/models/Question.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class HomeScreen extends StatefulWidget{

  @override
  _HomeScreenState createState()=> _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final GlobalKey<AnimatedListState> _ListKey=GlobalKey();
  List<Message> _data = [
    new Message(0,
        "مرحبا بك، يسعدني ان أجيب على أسئلتك حول كل ما يتعلق بحملة التلقيح ضد فيروس كرونا المستجد.",false,false)
  ];
  List<Question> _questions = [
    Question(1, "CNIE", "رقم بطاقة التعريف الوطنية" ),
    Question(2,"DateExpirationCnie" , "تاريخ انتهاء صلاحية بطاقة التعريف الوطنية (السنة/الشهر/اليوم)"),
    Question(3,"NomAr" , "الإسم العائلي"),
    Question(4, "txtJour", "تاريخ الازدياد (اليوم)"),
    Question(5, "txtMois", "تاريخ الازدياد (الشهر)"),
    Question(6, "txtAnnee", "تاريخ الازدياد (السنة)"),
    Question(7, "AC_Captcha", "المرجو نقل كلمة التحقق")
  ];

  bool search = false;
  bool chooseYes = false;
  int indexQ = 1;
  bool buttonsClicked = false;
  bool captcha = false;
  String respData = "";

  Map<String,String> _formData = new Map<String,String>();

  TextEditingController queryController=TextEditingController();
  final BOT_URL = "https://chatbotliq.herokuapp.com";
  ScrollController _scrollController = new ScrollController();
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              height: 60,
            ),
            Container(
                padding: const EdgeInsets.all(8.0), child: Text('Chatbot Liqahona',style: TextStyle(color: Colors.indigo),))
          ],

        ),
      ),
      body: Stack(
        children: <Widget>[

          ListView.builder(
            key: _ListKey,
            controller: _scrollController,
            itemCount: _data.length,
            shrinkWrap: true,
            padding: EdgeInsets.only(top: 10,bottom: 100),
            itemBuilder: (context, index){
                return buildItem(_data[index],index);
            },
          ),

          Stack(
            children: [
              SizedBox(height:30,),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.linearToSrgbGamma(),
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.only(left: 20,right: 20),
                        child: TextField(
                          textAlign: TextAlign.end,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(

                            hintText: "هل يمكنك تحديد مركز تلقيحي",
                            fillColor: Colors.blueGrey,
                            icon: Icon(
                              Icons.message,
                              color: Colors.indigo,
                            ),
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
              ),
            ],
          )
        ],
      ),
    );
  }

  //response
  void getResponse(){

    if(!search){
      if(queryController.text.length>0){
        String txt = queryController.text.replaceAll("‏", "");
        this.insertSingleItem(txt,1,false,false);
        var client = getClient();
        try{
          client.post(
            Uri.parse(BOT_URL+"/chat"),
            body: {"message":txt},
          ).then((responses){
            Map<String,dynamic> data=jsonDecode(responses.body);
            insertSingleItem(data['message'],0,false,false);
            if (data["action"] == "search") {
              this.insertSingleItem(
                  "لمعرفة المكان أو مركز التلقيح الخاص بك إضغط نعم", 0,false,false);
              this.insertSingleItem(
                  "", 0,true,false);
              setState(() {
                buttonsClicked = false;
                search = true;
              });
            }
          });
        }finally{
          client.close();
        }
      }
    }else{
      String txt = queryController.text.replaceAll("‏", "");
      this.insertSingleItem(txt,1,false,false);
      _formData[_questions[indexQ-2].id] = txt;
      print(_formData);
    }
    if(chooseYes){
      this.insertSingleItem(_questions[indexQ-1].q,0,false,false);
      setState(() {
        indexQ++;
      });
      if(indexQ == _questions.length+1){
        setState(() {
          captcha = true;
          chooseYes = false;
        });
      }
    }
    if(captcha){
      var client = getClient();
      try{
        client.get(
          Uri.parse(BOT_URL+"/openSession"),
        ).then((responses) {
          setState(() {
            respData = responses.body;
            captcha = false;
          });
          this.insertSingleItem(
              "", 0,false,true);
        });
      }
      finally{
        client.close();
      }
    }
    if(_formData.length == _questions.length){
      var client = getClient();
      try{
        client.post(
          Uri.parse(BOT_URL+"/check"),
            body: _formData
        ).then((responses) {
          setState(() {
            search = false;
            _formData = new Map<String,String>();
            indexQ = 1;
          });
          Map<String,dynamic> rData = json.decode(responses.body);
          if(rData["essbAdresse"]  == ""){
            this.insertSingleItem(
                "المعلومات خاطئة للمحاولة من جديد إضغط نعم", 0,false,false);
          }else{
            String d =" `  مركز التلقيح الخاص بك :${rData["essbAdresse"]}   العمالة / الاقليم : ${rData["province"]}   الجماعة او المقاطعة  : ${rData["commune"]}";
            this.insertSingleItem(
                d, 0,false,false);
          }
        });
      }
      finally{
        client.close();
      }
    }
    queryController.clear();
  }



  void insertSingleItem(String message,int type,bool show,bool check){
    Timer(
        Duration(milliseconds: 100),
            () => _scrollController
            .jumpTo(_scrollController.position.maxScrollExtent));
    setState(() {
      _data.add(new Message(type,message,show,check));
    });

  }
  http.Client getClient(){
    return http.Client();
  }

  Widget buildItem(Message m,int index){
    return m.isCheckImage?
          Image.network(BOT_URL+"/image/"+respData)
        :(m.isYesORNoButton?
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed:buttonsClicked ? null: (){
              this.insertSingleItem("نعم",1,false,false);
              this.insertSingleItem(_questions[indexQ-1].q,0,false,false);
              setState(() {
                buttonsClicked = true;
                chooseYes = true;
                indexQ++;
              });
            },child:Text("نعم"),style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blueGrey)),),
            ElevatedButton(onPressed:buttonsClicked ? null : (){
              this.insertSingleItem("لا",1,false,false);
              setState(() {
                buttonsClicked = true;
              });
            },
                child:Text("لا"),
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.black87)))
          ],
        )
        :(m.type == 0?botMessage(m.msg):userMessage(m.msg)));
  }
}


Widget botMessage(msg){
  return Row(
     crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        backgroundImage: AssetImage("assets/robot.png"),
        backgroundColor: Colors.white,
      ),
      Container(
        padding: const EdgeInsets.all(15.0),
        margin: EdgeInsets.symmetric(horizontal: 0,vertical: 20),
        width: 300,
        decoration: BoxDecoration(
          color: Colors.indigo,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(25),
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
        ),
        child: Text(
          "${msg}",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      )
    ],

  );
}

Widget userMessage(msg){
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.all(15.0),
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Text(
          "${msg}",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      CircleAvatar(
        backgroundImage: AssetImage("assets/user.png"),
        backgroundColor: Colors.white,
      ),

    ],
  );
}

