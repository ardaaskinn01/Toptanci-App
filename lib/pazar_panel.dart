import 'package:flutter/material.dart';

class PazarPanel extends StatefulWidget {
  const PazarPanel({Key? key}) : super(key: key);

  @override
  _PazarPanelState createState() => _PazarPanelState();
}

class _PazarPanelState extends State<PazarPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pazarlama Paneli'),
      ),
      body: Center(
        child: Text('Pazarlama Paneli'),
      ),
    );
  }
}
