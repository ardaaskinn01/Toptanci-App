import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Pazarlamaci extends StatefulWidget {
  final String id;
  final String name;

  const Pazarlamaci({
    Key? key,
    required this.id,
    required this.name,
  }) : super(key: key);

  @override
  _PazarlamaciState createState() => _PazarlamaciState();
}

class _PazarlamaciState extends State<Pazarlamaci> {
  String? selectedProduct;
  int? stokAmount;
  bool isLoading = false;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Ürünleri getiren fonksiyon (sadece mudurID ile eşleşen ürünler)
  Future<List<Map<String, dynamic>>> _getUrunler() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('urunler')
        .where('mudurID', isEqualTo: currentUserId)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['isim'],
      };
    }).toList();
  }

  // Kullanıcı stoklarını getiren fonksiyon
  Future<List<Map<String, dynamic>>> _getStoklar() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.id)
        .collection('stoklar')
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'stok': doc['stok'],
      };
    }).toList();
  }

  // Stok ekleme veya güncelleme işlemi
  Future<void> _addOrUpdateStokToUser(String productName, int stok) async {
    setState(() {
      isLoading = true;
    });

    try {
      final urunlerRef = FirebaseFirestore.instance.collection('urunler');
      final stoklarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.id)
          .collection('stoklar');

      // Ürün sorgusu
      final querySnapshot =
      await urunlerRef.where('isim', isEqualTo: productName).get();
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Seçilen ürün bulunamadı.');
      }

      // Ürün bilgilerini al ve doküman ID'sini kaydet
      final productDoc = querySnapshot.docs.first;
      final productId = productDoc.id; // Doküman ID'si
      final productData = productDoc.data();
      final double productPrice = productData['fiyat'];
      final String barcode = productData['barcode'];

      // Kullanıcının stoklarını kontrol et
      final stokDoc = await stoklarRef.doc(productId).get();
      final currentStok = stokDoc.exists ? stokDoc['stok'] : 0;

      if (stokDoc.exists) {
        // Eğer stok mevcutsa güncelle
        await stoklarRef.doc(productId).update({
          'stok': currentStok + stok,
          'fiyat': productPrice,
        });
      } else {
        // Eğer stok yoksa yeni doküman oluştur
        await stoklarRef.doc(productId).set({
          'name': productName,
          'stok': stok,
          'fiyat': productPrice,
          'barcode': barcode,
        });
      }

      // Ürünün kendi stoklarından düşüş yap
      final productRef = FirebaseFirestore.instance.collection('urunler').doc(productId);
      final productSnapshot = await productRef.get();
      if (productSnapshot.exists) {
        final currentProductStok = productSnapshot['stok'];
        await productRef.update({'stok': currentProductStok - stok});
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ürün başarıyla güncellendi. Yeni stok: ${currentStok + stok}'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Stok düşürme işlemi
  Future<void> _reduceStok(String productName, int stok) async {
    setState(() {
      isLoading = true;
    });
    try {
      final stoklarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.id)
          .collection('stoklar');

      // Seçilen ürünün stoklar koleksiyonundaki dokümanını al
      final stokQuerySnapshot =
      await stoklarRef.where('name', isEqualTo: productName).get();

      if (stokQuerySnapshot.docs.isEmpty) {
        throw Exception('Ürün stokta bulunamadı.');
      }

      // Doküman ID ve mevcut stok
      final stokDoc = stokQuerySnapshot.docs.first;
      final docId = stokDoc.id;
      final currentStok = stokDoc['stok'];

      // Stok kontrolü
      if (currentStok < stok) {
        throw Exception('Stok yetersiz. Mevcut stok: $currentStok');
      }

      // Stok düşürme işlemi
      await stoklarRef.doc(docId).update({
        'stok': currentStok - stok,
      });
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Stok başarıyla güncellendi. Yeni stok: ${currentStok - stok}'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showCustomDialog({
    required String title,
    required String actionLabel,
    required Function(String productName, int stok) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(

                  // Ürünleri filtrelenmiş olarak getiriyoruz
                  future: _getUrunler(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('Ürün bulunamadı.');
                    }

                    final urunler = snapshot.data!;
                    return DropdownButton<String?>(

                      // Dropdown'da ürünleri listele
                      isExpanded: true,
                      value: selectedProduct,
                      hint: Text('Ürün Seçin'),
                      items: urunler.map((urun) {
                        return DropdownMenuItem<String?>(

                          value: urun['name'],
                          child: Text(urun['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProduct = value;
                        });
                      },
                    );
                  },
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    stokAmount = int.tryParse(value);
                  },
                  decoration: InputDecoration(labelText: 'Stok Miktarı'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedProduct != null && stokAmount != null) {
                    onConfirm(selectedProduct!, stokAmount!);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Tüm bilgileri doldurun.'),
                      backgroundColor: Colors.orange,
                    ));
                  }
                },
                child: Text(actionLabel),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil - ${widget.name}'),
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(

              // Kullanıcının stoklarını getiriyoruz
              future: _getStoklar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Hata: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Bu kullanıcıya ait stok bulunamadı.'));
                }

                final stoklar = snapshot.data!;
                return ListView.builder(
                  itemCount: stoklar.length,
                  itemBuilder: (context, index) {
                    final stok = stoklar[index];
                    return Card(
                      child: ListTile(
                        title: Text(stok['name']),
                        subtitle: Text('Stok: ${stok['stok']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle),
                          onPressed: () => _reduceStok(stok['name'], 1),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomDialog(
          title: 'Pazarlamaci Stok Ekleme',
          actionLabel: 'Stok Ekle',
          onConfirm: _addOrUpdateStokToUser,
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
