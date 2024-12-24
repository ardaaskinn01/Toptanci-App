import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kullanicilar.dart';
import 'urunler.dart';
import 'main.dart'; // Login sayfasını içeri aktarın

class MudurPanel extends StatefulWidget {
  final String id;
  const MudurPanel({Key? key, required this.id}) : super(key: key);

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
      final userDoc = await _firestore.collection('users').doc(widget.id).get();
      setState(() {
        displayName = userDoc.data()?['name'] ?? 'Misafir';
      });
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
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
                decoration: InputDecoration(labelText: 'Kullanıcı Adı'),
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
                  // Firestore'a kullanıcı bilgisi ekleme
                  await _firestore.collection('users').add({
                    'name': name,
                    'role': role,
                    'id': id,
                    'password': password,
                    'mudurID': widget.id
                  });

                  // Ekleme işlemi başarılı olursa
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pazarlamacı başarıyla eklendi!')),
                  );
                } catch (e) {
                  print("Hata: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata oluştu: $e')),
                  );
                }
              },
              child: Text('Ekle'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _addUrun(BuildContext context) async {
    String isim = '', fiyat = '', stok = '', barkod = '';

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
              TextField(
                decoration: InputDecoration(labelText: 'Barkod Numarası'),
                onChanged: (value) => barkod = value,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Firestore veritabanına ürünü kaydet
                  await _firestore.collection('urunler').add({
                    'isim': isim,
                    'fiyat': double.parse(fiyat),
                    'stok': int.parse(stok),
                    'barcode': barkod, // Barkod numarasını ekliyoruz
                    'mudurID': widget.id
                  });

                  Navigator.pop(ctx); // Dialogu kapat
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ürün başarıyla eklendi!')),
                  );
                } catch (e) {
                  print("Hata: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata oluştu: $e')),
                  );
                }
              },
              child: Text('Ekle'),
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
        title: Text(
          'Müdür Paneli',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade300, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addPazarlamaci(context),
                  icon: Icon(Icons.person_add, size: 24),
                  label: Text('Pazarlamacı Ekle', style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.red,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _addUrun(context),
                  icon: Icon(Icons.add_shopping_cart, size: 24),
                  label: Text('Ürün Ekle', style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.deepOrange.shade500,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => KullaniciListesi()),
                  ),
                  icon: Icon(Icons.people, size: 24),
                  label: Text('Pazarlamacılar'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.orange.shade500,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UrunListesi()),
                  ),
                  icon: Icon(Icons.inventory, size: 24),
                  label: Text('Ürünler'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.orange.shade300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
