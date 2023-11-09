import 'package:flutter/material.dart';

import 'chapleapp.dart';


class HomePage extends StatefulWidget {
  final String groupName;

  HomePage({required this.groupName});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _memberController = TextEditingController();
  List<String?> addMemberList = [];
  List<String?> addAdminList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HomePage'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              customTextField(
                hintText: 'Member Id',
                textEditController: _memberController,
              ),
              Divider(
                color: Colors.black,
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
