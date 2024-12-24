import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pazarlamaci.dart'; // Profil sayfası için gerekli dosya
import 'package:firebase_auth/firebase_auth.dart';

class KullaniciListesi extends StatelessWidget {
  const KullaniciListesi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser; // current user'ı al

    if (currentUser == null) {
      // Kullanıcı giriş yapmamışsa, bir hata mesajı göster
      return Scaffold(
        appBar: AppBar(
          title: Text('Pazarlamacılar'),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Text('Kullanıcı giriş yapmamış.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pazarlamacılar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'pazarlama') // Rolü pazarlama olanları filtrele
            .where('mudurID', isEqualTo: currentUser.uid) // MudurID ile eşleşenleri filtrele
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          print(currentUser.uid);
          final users = snapshot.data!.docs;
          if (users.isEmpty) {
            return Center(
              child: Text(
                'Hiç pazarlamacı bulunamadı.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: Colors.teal[50],
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    user['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${user["id"]}\nŞifre: ${user['password']}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.teal[900],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Pazarlamaci(
                          id: user.id,
                          name: user['name'],
                        ),
                      ),
                    );
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
