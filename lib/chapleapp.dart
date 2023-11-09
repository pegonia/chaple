import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xmpp_plugin/error_response_event.dart';
import 'package:xmpp_plugin/models/chat_state_model.dart';
import 'package:xmpp_plugin/models/connection_event.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:xmpp_plugin/models/present_mode.dart';
import 'package:xmpp_plugin/success_response_event.dart';
import 'package:xmpp_plugin/xmpp_plugin.dart';

import 'homepage.dart';
import 'native_log_helper.dart';
import 'utils.dart';

const myTask = "syncWithTheBackEnd";

class ChapleApp extends StatefulWidget {
  @override
  _ChapleAppState createState() => _ChapleAppState();
}

class _ChapleAppState extends State<ChapleApp>
    with WidgetsBindingObserver
    implements DataChangeEvents {
  static late XmppConnection flutterXmpp;
  List<MessageChat> events = [];
  List<PresentModel> presentMo = [];
  String connectionStatus = "Disconnected";
  String connectionStatusMessage = "";
  String lastMessage = "-----------";

  @override
  void initState() {
    checkStoragePermission();
    XmppConnection.addListener(this);
    super.initState();
    log('didChangeAppLifecycleState() initState');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    XmppConnection.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    log('didChangeAppLifecycleState() dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('didChangeAppLifecycleState()');
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        log('detachedCallBack()');
        break;
      case AppLifecycleState.resumed:
        log('resumed detachedCallBack()');
        break;
      case AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }

  Future<void> connect() async {
    final auth = {
      "user_jid":
          "${_userNameController.text}@chat.froheswerk.de/${Platform.isAndroid ? "Android" : "iOS"}",
      "password": "chaple",
      "host": "chat.froheswerk.de",
      "port": '5222',
      "nativeLogFilePath": NativeLogHelper.logFilePath,
      "requireSSLConnection": true,
      "autoDeliveryReceipt": true,
      "useStreamManagement": false,
      "automaticReconnection": true,
    };

    flutterXmpp = XmppConnection(auth);
    await flutterXmpp.start(_onError);
    await flutterXmpp.login();
  }

  void checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      final PermissionStatus _permissionStatus =
          await Permission.storage.request();
      if (_permissionStatus.isGranted) {
        String filePath = await NativeLogHelper().getDefaultLogFilePath();
        print('logFilePath: $filePath');
      } else {
        print('logFilePath: please allow permission');
      }
    } else {
      String filePath = await NativeLogHelper().getDefaultLogFilePath();
      print('logFilePath: $filePath');
    }
  }

  void _onError(Object error) {
    // TODO : Handle the Error event
  }

  @override
  void onXmppError(ErrorResponseEvent errorResponseEvent) {
    print(
        'receiveEvent onXmppError: ${errorResponseEvent.toErrorResponseData().toString()}');
  }

  @override
  void onSuccessEvent(SuccessResponseEvent successResponseEvent) {
    print(
        'receiveEvent successEventReceive: ${successResponseEvent.toSuccessResponseData().toString()}');
  }

  @override
  void onChatMessage(MessageChat messageChat) {
    events.add(messageChat);
    print('onChatMessage: ${messageChat.toEventData()}');
  }

  @override
  void onGroupMessage(MessageChat messageChat) {
    events.add(messageChat);
    print('onGroupMessage: ${messageChat.toEventData()}');
    setState(() {
      lastMessage = messageChat.body ?? "";
    });
  }

  @override
  void onNormalMessage(MessageChat messageChat) {
    events.add(messageChat);
    print('onNormalMessage: ${messageChat.toEventData()}');
  }

  @override
  void onPresenceChange(PresentModel presentModel) {
    presentMo.add(presentModel);
    log('onPresenceChange ~~>>${presentModel.toJson()}');
  }

  String dropDownValue = 'chaple';
  var items = ['chaple', 'AG Orga', 'AG Tec'];

  @override
  void onChatStateChange(ChatState chatState) {
    log('onChatStateChange ~~>>$chatState');
  }

  @override
  void onConnectionEvents(ConnectionEvent connectionEvent) {
    log('onConnectionEvents ~~>>${connectionEvent.toJson()}');
    connectionStatus = connectionEvent.type!.toConnectionName();
    connectionStatusMessage = connectionEvent.error ?? '';
    setState(() {});
  }

  Future<void> disconnectXMPP() async => await flutterXmpp.logout();

  Future<bool> joinMucGroup(String groupId) async {
    return await flutterXmpp.joinMucGroup(groupId);
  }

  TextEditingController _userNameController =
      TextEditingController(text: "frieder.nollau");

  TextEditingController _messageController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Chaple Erste Schritte'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Username',
                  textEditController: _userNameController,
                  addKey: true,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (connectionStatus == 'Authenticated') {
                          await disconnectXMPP();
                        } else {
                          await connect();
                        }
                      },
                      child: Text(connectionStatus == 'authenticated'
                          ? "Trennen"
                          : "Verbinden"),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                DropdownButton(
                  value: dropDownValue,
                  icon: Icon(Icons.keyboard_arrow_down),
                  items: items.map(
                    (String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    },
                  ).toList(),
                  onChanged: (val) {
                    setState(
                      () {
                        dropDownValue = val.toString();
                      },
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            dropDownValue = "chaple"; // fixe gruppe
                            _joinGroup(context,
                                "${dropDownValue}@conference.chat.froheswerk.de");
                          },
                          child: Text('Gruppe beitreten'),
                          style: ElevatedButton.styleFrom(),
                        ),
                      ],
                    );
                  },
                ),
                customTextField(
                  hintText: "Nachricht",
                  textEditController: _messageController,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        int id = DateTime.now().millisecondsSinceEpoch;
                        await flutterXmpp.sendGroupMessageWithType(
                            "${dropDownValue}@conference.chat.froheswerk.de",
                            "${_messageController.text}",
                            "$id",
                            DateTime.now().millisecondsSinceEpoch);
                      },
                      child: Text(" Sende "),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Text(lastMessage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _joinGroup(BuildContext context, String grouname,
      {bool isManageGroup = false}) async {
    bool response = await joinMucGroup("$grouname");
    flutterXmpp.sendGroupMessageWithType(
        "${dropDownValue}@conference.chat.froheswerk.de",
        "Hi, da bin ich...",
        DateTime.now().millisecondsSinceEpoch.toString(),
        DateTime.now().millisecondsSinceEpoch);
    if (response && isManageGroup) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            groupName: grouname,
          ),
        ),
      );
    }
  }
}

Widget customTextField({
  TextEditingController? textEditController,
  String? hintText,
  bool addKey = false,
}) {
  return TextField(
    key: addKey ? Key(hintText!) : null,
    autocorrect: false,
    controller: textEditController,
    cursorColor: Colors.black,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 16,
        color: Colors.grey.withOpacity(0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(5.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: BorderSide(
          color: Colors.grey,
        ),
      ),
    ),
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );
}
