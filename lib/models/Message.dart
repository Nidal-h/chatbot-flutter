import 'package:flutter/cupertino.dart';

class Message{
  int type;
  String msg;
  bool isYesORNoButton;
  bool isCheckImage;
  Message(this.type,this.msg,this.isYesORNoButton,this.isCheckImage);
}