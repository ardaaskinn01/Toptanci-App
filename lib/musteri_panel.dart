import 'package:flutter/material.dart';

class MusteriPanel extends StatefulWidget {
  const MusteriPanel({Key? key}) : super(key: key);

  @override
  _MusteriPanelState createState() => _MusteriPanelState();
}

class _MusteriPanelState extends State<MusteriPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Müşteri Paneli'),
      ),
      body: Center(
        child: Text('Müşteri Paneli'),
      ),
    );
  }
}
