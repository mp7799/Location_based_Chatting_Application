import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:module_group_chat/chat_screen.dart';

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  Location _locationService = Location();
  bool _permission = false;
  String error;
  bool currentWidget = true;
  bool locationGranted = false;
  String groupName = '';
  double latitudeSum = 0,
      longitudeSum = 0,
      averageLatitude = 0,
      averageLongitude = 0;
  int count = 0;
  bool groupList = false;

  Firestore _firestore = Firestore.instance;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    await _locationService.changeSettings(
        accuracy: LocationAccuracy.HIGH, interval: 1);

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      bool serviceStatus = await _locationService.serviceEnabled();
      print("Service status: $serviceStatus");
      if (serviceStatus) {
        _permission = await _locationService.requestPermission();
        print("Permission: $_permission");
        if (_permission) {
          setState(() {
            locationGranted = true;
          });
        }
      } else {
        bool serviceStatusResult = await _locationService.requestService();
        print("Service status activated after request: $serviceStatusResult");
        if (serviceStatusResult) {
          initPlatformState();
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        error = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        error = e.message;
      }
    }
    callThreeTimes();
  }

  Future getLoc() async {
    LocationData location;
    List<dynamic> latlon = [];
    location = await _locationService.getLocation();
    latlon.add(location.latitude);
    latlon.add(location.longitude);
    return latlon;
  }

  callThreeTimes() async {
    for (int i = 0; i < 1; i++) {
      await getLoc().then((v) {
        latitudeSum = latitudeSum + v[0];
        longitudeSum = longitudeSum + v[1];
        setState(() {
          count++;
        });
      });
    }

    String temp1, temp2;
    averageLatitude = latitudeSum / 1;
    averageLongitude = longitudeSum / 1;
    temp1 = averageLatitude.toStringAsFixed(7);
    temp2 = averageLongitude.toStringAsFixed(7);
    averageLatitude = double.parse(temp1);
    averageLongitude = double.parse(temp2);

    print(averageLatitude);
    print(averageLongitude);
  }

//  justNothing() async {
//    await _firestore.collection('SRM').getDocuments().then((snapshot) {
//      for (DocumentSnapshot ds in snapshot.documents) {
//        final x = ds.documentID;
//        if (x == 'Hello') {
//          final y = ds.data['lowerLongitudeLimit'];
//          print(y);
//        }
//      }
//    });
//  }

  createGroup() async {
    setState(() {
      count = 0;
    });

    //QuerySnapshot querySnapshot = await _firestore.collection('SRM').getDocuments(); // -- Kept Just for future references

    await (_firestore.collection('SRM').document(groupName).setData({
      'lowerLatitudeLimit': averageLatitude - 0.0001700,
      'lowerLongitudeLimit': averageLongitude - 0.0001700,
      'upperLatitudeLimit': averageLatitude + 0.0001700,
      'upperLongitudeLimit': averageLongitude + 0.0001700,
    })).then((v) async {
      await _firestore
          .collection('SRM')
          .document(groupName)
          .collection(groupName)
          .document('Hidden Document')
          .setData({'text': 'Garbage Data'});
      setState(() {
        count = 3;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Group-Chat Testing'),
          ),
        ),
        body: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 70.0,),
                    Container(
                      height: 20.0,
                      width: 20.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: count == 1 ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    count == 1
                        ? Text('Location Successfully Fetched')
                        : Text('Fetching Your Location'),
                  ],
                ),
                SizedBox(
                  height: 200.0,
                ),
                Center(
                  child: locationGranted
                      ? Column(
                          children: <Widget>[
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: TextField(
                                onChanged: (v) {
                                  setState(() {
                                    groupName = v;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  RaisedButton(
                                    color: Colors.blue,
                                    child: Text(
                                      'Create Connection',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: count == 1
                                        ? () {
                                            createGroup();
                                          }
                                        : null,
                                  ),
                                  RaisedButton(
                                    color: Colors.blueAccent,
                                    child: Text(
                                      'Join A Connection',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: count == 1
                                        ? () async {
                                            //justNothing();
                                            setState(() {
                                              groupList = true;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            groupList
                                ? StreamBuilder<QuerySnapshot>(
                                    stream:
                                        _firestore.collection('SRM').snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: CircularProgressIndicator(
                                            backgroundColor: Colors.lightBlueAccent,
                                          ),
                                        );
                                      }
                                      final docs = snapshot.data.documents;
                                      List<MessageBubble> messageBubbles = [];
                                      for (var doc in docs) {
                                        final lowerLatitudeLimit =
                                            doc.data['lowerLatitudeLimit'];
                                        final lowerLongitudeLimit =
                                            doc.data['lowerLongitudeLimit'];
                                        final upperLatitudeLimit =
                                            doc.data['upperLatitudeLimit'];
                                        final upperLongitudeLimit =
                                            doc.data['upperLongitudeLimit'];

//                              print(message.documentID);
//                              print(lowerLatitudeLimit);
//                              print(lowerLongitudeLimit);
//                              print(upperLatitudeLimit);
//                              print(upperLongitudeLimit);

                                        if (averageLatitude > lowerLatitudeLimit &&
                                            averageLatitude < upperLatitudeLimit &&
                                            averageLongitude >
                                                lowerLongitudeLimit &&
                                            averageLongitude <
                                                upperLongitudeLimit) {
                                          final messageBubble = MessageBubble(
                                            gpName: doc.documentID,
                                          );
                                          messageBubbles.add(messageBubble);
                                        }
                                      }
                                      return Container(
                                        height: 300.0,
                                        width:
                                            MediaQuery.of(context).size.width * 0.8,
                                        child: ListView(
                                          children: messageBubbles,
                                        ),
                                      );
                                    },
                                  )
                                : Text(''),
                          ],
                        )
                      : RaisedButton(
                          child:
                              Text('You have Denied Locatin Access Press To Retry'),
                          onPressed: () {
                            initPlatformState();
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              count = 0;
              groupList = false;
              averageLongitude = 0;
              averageLongitude = 0;
              latitudeSum = 0;
              longitudeSum = 0;
            });
            callThreeTimes();
          },
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.gpName});
  final gpName;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FlatButton(
          child: Text(
            gpName,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          color: Color(0xffe9bf9c),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatScreen(
                      collectionName: gpName,
                    )));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        SizedBox(
          height: 5.0,
        )
      ],
    );
  }
}
