import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UrunListesi extends StatelessWidget {
  const UrunListesi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ürünler'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('urunler').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final urunler = snapshot.data!.docs;
          return ListView.builder(
            itemCount: urunler.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(urunler[index]['isim']),
                subtitle: Text(
                    'Fiyat: ${urunler[index]['fiyat']} - Stok: ${urunler[index]['stok']}'),
              );
            },
          );
        },
      ),
    );
  }
}
