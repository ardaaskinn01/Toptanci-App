import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kullanicilar.dart';
import 'urunler.dart';

class MudurPanel extends StatefulWidget {
  const MudurPanel({Key? key}) : super(key: key);

  @override
  _MudurPanelState createState() => _MudurPanelState();
}

class _MudurPanelState extends State<MudurPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        displayName = userDoc.data()?['name'] ?? 'Misafir';
      });
      print(displayName);
    }
  }

  Future<void> _addPazarlamaci(BuildContext context) async {
    String name = '', id = '', password = '', role = 'pazarlama';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Pazarlamacı Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'İsim'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'ID'),
                onChanged: (value) => id = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Şifre'),
                onChanged: (value) => password = value,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _firestore.collection('users').doc(id).set({
                    'name': name,
                    'role': role,
                    'password': password,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pazarlamacı başarıyla eklendi!')),
                  );
                } catch (e) {
                  print("Hata: $e");
                }
              },
              child: Text('Ekle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addUrun(BuildContext context) async {
    String isim = '', fiyat = '', stok = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Ürün Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Ürün İsmi'),
                onChanged: (value) => isim = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Fiyat'),
                onChanged: (value) => fiyat = value,
                keyboardType: TextInputType.number,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Stok'),
                onChanged: (value) => stok = value,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _firestore.collection('urunler').add({
                    'isim': isim,
                    'fiyat': double.parse(fiyat),
                    'stok': int.parse(stok),
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ürün başarıyla eklendi!')),
                  );
                } catch (e) {
                  print("Hata: $e");
                }
              },
              child: Text('Ekle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Müdür Paneli - Hoşgeldin, $displayName'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _addPazarlamaci(context),
              child: Text('Pazarlamacı Ekle'),
            ),
            ElevatedButton(
              onPressed: () => _addUrun(context),
              child: Text('Ürün Ekle'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KullaniciListesi()),
              ),
              child: Text('Kullanıcılar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UrunListesi()),
              ),
              child: Text('Ürünler'),
            ),
          ],
        ),
      ),
    );
  }
}
