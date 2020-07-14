import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

final _firestore = Firestore.instance;

class ChatScreen extends StatefulWidget {
  ChatScreen({@required this.collectionName});
  final String collectionName;

  static String routeName = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  _ChatScreenState({@required this.groupName});

  String messageText;
  String prevMessage = '';
  bool _isTyping = false;
  String groupName;
  int times = 5;
  String lastMessage;
  int sec = 0;
  Timer timer;
  final messageTextController = TextEditingController();

  accessingGroupName(String gpname) {
    setState(() {
      groupName = gpname;
    });
  }

  @override
  void initState() {
    super.initState();
    checkActivityState();
    accessingGroupName(widget.collectionName);
  }

  checkActivityState() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      checkDifference();
    });
  }

  int hour(String time) {
    List temp;
    temp = time.split(" ");
    time = temp[1];
    temp = [];
    temp = time.split(".");
    time = temp[0];
    temp = [];
    temp = time.split(":");
    int hours;
    hours = int.parse(temp[0]);
    return hours;
  }

  int minutes(String time) {
    List temp;
    temp = time.split(" ");
    time = temp[1];
    temp = [];
    temp = time.split(".");
    time = temp[0];
    temp = [];
    temp = time.split(":");
    int minute;
    minute = int.parse(temp[1]);
    return minute;
  }

  int seconds(String time) {
    List temp;
    temp = time.split(" ");
    time = temp[1];
    temp = [];
    temp = time.split(".");
    time = temp[0];
    temp = [];
    temp = time.split(":");
    int second;
    second = int.parse(temp[2]);
    return second;
  }

  checkDifference() {
    String currentTime = DateTime.now().toString();
    String lastActivityTime = lastMessage;

    int currentTimeHour = hour(currentTime);
    int currentTimeMinutes = minutes(currentTime);
    int currentTimeSeconds = seconds(currentTime);

    int lastActivityTimeHour = hour(lastActivityTime);
    int lastActivityTimeMinutes = minutes(lastActivityTime);
    int lastActivityTimeSeconds = seconds(lastActivityTime);

    if (lastActivityTimeSeconds > 40) {
      lastActivityTimeSeconds = lastActivityTimeSeconds - 20;
    }
    print(lastActivityTimeSeconds);
    print(currentTimeSeconds);

    if (lastActivityTimeSeconds + 10 <= currentTimeSeconds) {
      Navigator.pop(context);
    }
  }

  stopTyping() {
    setState(() {
      _isTyping = false;
    });
    sec = 0;
  }

  typingState(String value, int seconds) {
    if (prevMessage != value) {
      setState(() {
        _isTyping = true;
      });
      prevMessage = value;
      typingState(prevMessage, sec);
    } else {
      sec = sec + 5;
      Timer(Duration(seconds: sec), () {
        stopTyping();
      });
    }
  }

  lstMessage(String message) {
    lastMessage = message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
//                _auth.signOut();
//                Navigator.pop(context);
                //Implement logout functionality
              }),
        ],
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('⚡️$groupName'),
            if (_isTyping)
              Text(
                'Manpreet is typing.....',
                style: TextStyle(fontSize: 15.0),
              )
          ],
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(
              groupName: groupName,
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                        if (messageText.length % 2 == 0) {
                          typingState(messageText, sec);
                        }
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      setState(() {
                        lastMessage = DateTime.now().toString();
                      });
                      _firestore
                          .collection('SRM')
                          .document(groupName)
                          .collection(groupName)
                          .document(lastMessage)
                          .setData({
                        'text': messageText,
                      }); //Implement send functionality.
                      setState(() {
                        _isTyping = false;
                        times = 5;
                      });
                      sec = 0;
                      messageTextController.clear();
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                  RaisedButton(
                    onPressed: () {
                      print(lastMessage);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  MessageStream({this.groupName});
  final groupName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('SRM')
          .document(groupName)
          .collection(groupName)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: Colors.lightBlueAccent,
          ));
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.data['text'];
          if (message.documentID != 'Hidden Document') {
            final messageBubble = MessageBubble(
              sender: 'Default',
              text: messageText,
              isMe: true,
            );
            messageBubbles.add(messageBubble);
          }
        }
        return Expanded(
          child: ListView(
            reverse: true,
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});
  final String sender, text;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              color: Colors.black38,
              fontSize: 12,
            ),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0)),
            elevation: 10,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 15.0, color: isMe ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
