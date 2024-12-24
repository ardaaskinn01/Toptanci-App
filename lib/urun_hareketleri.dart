import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductMovementsScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProductMovementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hareket detaylarını gösteren pop-up
    void showDetailsPopup(BuildContext context, Map<String, dynamic> product) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: Colors.white, // Arka plan rengini beyaz yapalım
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('users')
                    .doc(_auth.currentUser?.uid)
                    .collection('verilen_urunler')
                    .where('urunID', isEqualTo: product['id'])
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('Bu ürüne ait hareket bulunamadı.'));
                  }

                  final hareketler = snapshot.data!.docs;

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: hareketler.length,
                    itemBuilder: (context, index) {
                      final hareket = hareketler[index].data() as Map<String, dynamic>;

                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore
                            .collection('users')
                            .doc(hareket['musteriID'])
                            .get(),
                        builder: (context, musteriSnapshot) {
                          if (musteriSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                                title: Text('Yükleniyor...'),
                                subtitle: Text('Müşteri bilgileri alınıyor...'));
                          }
                          if (!musteriSnapshot.hasData || !musteriSnapshot.data!.exists) {
                            return const ListTile(
                              title: Text('Bilinmeyen Müşteri'),
                              subtitle: Text('Müşteri bilgisi bulunamadı.'),
                            );
                          }

                          final musteri = musteriSnapshot.data!.data() as Map<String, dynamic>;

                          // Fotoğraf verisini çözme işlemi
                          final photoData = musteri['photo'];
                          Uint8List? photoBytes;

                          if (photoData is List<dynamic>) {
                            photoBytes = Uint8List.fromList(List<int>.from(photoData));
                          } else if (photoData is String) {
                            final decodedBytes = base64Decode(photoData);
                            photoBytes = decodedBytes;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Müşteri fotoğrafını avatar olarak ekleyelim
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: photoBytes != null
                                        ? MemoryImage(photoBytes)
                                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hareket['name'] ?? 'Hareket İsmi Yok',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 5),
                                        Text('Adet: ${hareket['adet'] ?? 0}'),
                                        Text(
                                          'Tarih: ${DateFormat('dd/MM/yyyy').format(hareket['tarih']?.toDate() ?? DateTime.now())}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Müşteri: ${musteri['name'] ?? 'İsim Yok'}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Telefon: ${musteri['phone'] ?? 'Telefon Yok'}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.teal, // Renk uyumunu sağlamak için bir renk seçimi
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .collection('stoklar')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Kayıtlı ürün bulunamadı.'));
          }

          final products = snapshot.data!.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(product['name'] ?? 'Ürün İsmi Yok',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Stok: ${product['stok']} - Fiyat: ${product['fiyat']}₺',
                      style: const TextStyle(fontSize: 14)),
                  onTap: () => showDetailsPopup(context, product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
