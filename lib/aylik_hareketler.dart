import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AylikHareketlerScreen extends StatelessWidget {
  final String userId;

  AylikHareketlerScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aylık Hareketler"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(userId)
            .collection('verilen_urunler')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz bir hareket yok.'));
          }

          final aylikGruplar = <String, List<Map<String, dynamic>>>{};

          for (var doc in snapshot.data!.docs) {
            final urun = {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
            final tarih = urun['tarih']?.toDate() ?? DateTime.now();
            final ayKey = DateFormat('yyyy-MM').format(tarih);

            if (!aylikGruplar.containsKey(ayKey)) {
              aylikGruplar[ayKey] = [];
            }
            aylikGruplar[ayKey]!.add(urun);
          }

          final aylikKeys = aylikGruplar.keys.toList()..sort();

          return ListView.builder(
            itemCount: aylikKeys.length,
            itemBuilder: (context, index) {
              final ay = aylikKeys[index];
              final urunler = aylikGruplar[ay]!;

              final toplamAlinmasiGereken = urunler.fold(
                0.0,
                    (sum, urun) => sum + (urun['alinmasi_gereken'] ?? 0),
              );
              final toplamAlinanPara = urunler.fold(
                0.0,
                    (sum, urun) => sum + (urun['alinan_para'] ?? 0),
              );
              final toplamBorc = urunler.fold(
                0.0,
                    (sum, urun) => sum + (urun['borc'] ?? 0),
              );

              return Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.teal.shade50,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text("Ay: $ay", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Toplam İşlem: ${urunler.length}", style: const TextStyle(fontSize: 16)),
                      Text("Alınması Gereken: ₺$toplamAlinmasiGereken", style: const TextStyle(fontSize: 16)),
                      Text("Alınan Para: ₺$toplamAlinanPara", style: const TextStyle(fontSize: 16)),
                      Text("Borç: ₺$toplamBorc", style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.6,
                          minChildSize: 0.4,
                          maxChildSize: 0.9,
                          builder: (context, scrollController) {
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: urunler.length,
                              itemBuilder: (context, index) {
                                final urun = urunler[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(urun['name'] ?? 'Ürün İsmi Yok', style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Adet: ${urun['adet'] ?? 0}"),
                                        Text(
                                            "Tarih: ${DateFormat('dd/MM/yyyy').format(urun['tarih']?.toDate() ?? DateTime.now())}"),
                                        Text("Alınması Gereken Para: ₺${urun['alinmasi_gereken'] ?? 'Belirtilmemiş'}"),
                                        Text("Alınan Para: ₺${urun['alinan_para'] ?? 'Belirtilmemiş'}"),
                                        Text("Toplam Borç: ₺${urun['borc'] ?? 'Belirtilmemiş'}"),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
