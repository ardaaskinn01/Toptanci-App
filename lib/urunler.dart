import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'urun_dialog.dart';

class UrunListesi extends StatelessWidget {
  const UrunListesi({Key? key}) : super(key: key);

  Future<void> stokGuncelle(String urunId, int degisim) async {
    final urunRef =
    FirebaseFirestore.instance.collection('urunler').doc(urunId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(urunRef);
      if (snapshot.exists) {
        final mevcutStok = snapshot['stok'] ?? 0;
        transaction.update(urunRef, {'stok': mevcutStok + degisim});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ürünler',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('urunler').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final urunler = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: urunler.length,
            itemBuilder: (context, index) {
              final urun = urunler[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 6,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        urun['isim'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fiyat: ${urun['fiyat']} ₺',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Stok: ${urun['stok']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Barkod: ${urun['barcode']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => stokGuncelle(urun.id, -1),
                            icon: const Icon(Icons.remove, color: Colors.white),
                            label: const Text('Azalt', style: TextStyle(color: Colors.white),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => stokGuncelle(urun.id, 1),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Artır', style: TextStyle(color: Colors.white),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => UrunDialog(
                                  isim: urun['isim'],
                                  fiyat: urun['fiyat'],
                                  stok: urun['stok'],
                                  barcode: urun['barcode'],
                                  urunId: urun.id,
                                ),
                              );
                            },
                            child: const Text('Detaylar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
