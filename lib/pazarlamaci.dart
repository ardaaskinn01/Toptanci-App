import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  Future<List<Map<String, dynamic>>> _getStoklar(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('stoklar')
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'stok': doc['stok'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getUrunler() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('urunler').get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['isim'],
      };
    }).toList();
  }

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

      final querySnapshot =
      await urunlerRef.where('isim', isEqualTo: productName).get();
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Seçilen ürün bulunamadı.');
      }
      final productData = querySnapshot.docs.first.data();
      final int productPrice = productData['fiyat'];
      final String barcode = productData['barcode'];

      final stokQuerySnapshot =
      await stoklarRef.where('name', isEqualTo: productName).get();

      if (stokQuerySnapshot.docs.isNotEmpty) {
        final docId = stokQuerySnapshot.docs.first.id;
        final currentStok = stokQuerySnapshot.docs.first['stok'];
        await stoklarRef.doc(docId).update({
          'stok': currentStok + stok,
          'fiyat': productPrice,
        });
      } else {
        await stoklarRef.add({
          'name': productName,
          'stok': stok,
          'fiyat': productPrice,
          'barcode': barcode
        });
      }

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ürün başarıyla güncellendi.'),
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
              future: _getStoklar(widget.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Stok bulunamadı.'));
                }

                final stoklar = snapshot.data!;
                return ListView.builder(
                  itemCount: stoklar.length,
                  itemBuilder: (context, index) {
                    final urun = stoklar[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            urun['name'][0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          urun['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Stok: ${urun['stok']}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showCustomDialog(
                    title: 'Stok Ekle',
                    actionLabel: 'Ekle',
                    onConfirm: _addOrUpdateStokToUser,
                  ),
                  icon: Icon(Icons.add),
                  label: Text('Stok Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCustomDialog(
                    title: 'Stok Çıkar',
                    actionLabel: 'Çıkar',
                    onConfirm: (product, stok) => print('Çıkar işlem yapılacak'),
                  ),
                  icon: Icon(Icons.remove),
                  label: Text('Stok Çıkar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}