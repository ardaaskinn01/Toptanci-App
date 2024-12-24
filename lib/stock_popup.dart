import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StockPopup extends StatefulWidget {
  @override
  _StockPopupState createState() => _StockPopupState();
}

class _StockPopupState extends State<StockPopup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stok verisini almak için Future
  Future<QuerySnapshot> _getStokData() async {
    return await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid) // Şu anki kullanıcı
        .collection('stoklar') // Stoklar koleksiyonu
        .get();
  }

  // Stok miktarını bir azaltma fonksiyonu
  Future<void> _decreaseStock(String docId) async {
    try {
      var docRef = _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('stoklar')
          .doc(docId);

      var docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        var currentStock = docSnapshot['stok'];
        if (currentStock > 0) {
          // Stok miktarını bir azalt
          await docRef.update({'stok': currentStock - 1});
          setState(() {}); // Ekranı güncelle
        }
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  // Bir ürünün stoklarını sıfırlama fonksiyonu
  Future<void> _resetStock(String docId) async {
    try {
      var docRef = _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('stoklar')
          .doc(docId);

      // Stok miktarını sıfırla
      await docRef.update({'stok': 0});
      setState(() {}); // Ekranı güncelle
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Stoklar",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          SizedBox(height: 16),
          FutureBuilder<QuerySnapshot>(
            future: _getStokData(), // Veri almak için Future kullanıyoruz
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Bir hata oluştu', style: TextStyle(color: Colors.red));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text('Stokta ürün bulunmamaktadır.', style: TextStyle(color: Colors.grey));
              }

              // Stoklar listelenecek
              var stoklar = snapshot.data!.docs;
              return Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: stoklar.map((stok) {
                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            stok['name'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            'Stok: ${stok['stok']}',
                            style: TextStyle(color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Stok azaltma butonu
                              IconButton(
                                icon: Icon(Icons.remove, color: Colors.red),
                                onPressed: () {
                                  _decreaseStock(stok.id); // Stok miktarını azalt
                                },
                              ),
                              // Hepsini Sil butonu
                              TextButton(
                                child: const Text('Sıfırla', style: TextStyle(color: Colors.red),),
                                onPressed: () {
                                  _resetStock(stok.id); // O ürünü sıfırla
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Pop-up'ı kapat
            },
            child: Text('Kapat', style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
