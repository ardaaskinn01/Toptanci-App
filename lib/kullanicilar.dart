import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KullaniciListesi extends StatelessWidget {
  const KullaniciListesi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcılar'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(users[index]['name']),
                subtitle: Text('Rol: ${users[index]['role']}'),
              );
            },
          );
        },
      ),
    );
  }
}
