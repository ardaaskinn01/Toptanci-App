import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class CustomerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> customerData;

  const CustomerProfileScreen({Key? key, required this.customerData}) : super(key: key);

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedProductId;
  Uint8List? photoBytes; // Fotoğraf byte verisi

  @override
  void initState() {
    super.initState();
    _getCustomerPhoto();
  }

  void _getCustomerPhoto() async {
    try {
      // Firestore'dan fotoğraf verisini alıyoruz
      final docSnapshot = await _firestore.collection('users').doc(widget.customerData['docId']).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final photoData = data['photo']; // 'photo' alanındaki byte verisini al

        // photoData'nın List<int> veya başka bir türde olup olmadığını kontrol ediyoruz
        if (photoData is List<dynamic>) {
          // Veriyi List<int> türüne dönüştürüyoruz
          setState(() {
            photoBytes = Uint8List.fromList(List<int>.from(photoData));
          });
        } else if (photoData is String) {
          // Eğer photoData bir String ise, Base64 formatında olabilir
          // Base64 string'i çözebiliriz
          final decodedBytes = base64Decode(photoData);
          setState(() {
            photoBytes = decodedBytes; // Fotoğrafın byte verisini `photoBytes` olarak ayarla
          });
        } else {
          print("Geçersiz fotoğraf verisi");
        }
      }
    } catch (e) {
      print("Fotoğraf alınırken bir hata oluştu: $e");
    }
  }

  void _showProductDetailsPopup(BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('İşlemler: $productName'),
          content: SizedBox(
            height: 300, // Yükseklik sınırı koyuyoruz
            width: double.maxFinite, // Genişlik için maksimum değer
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.customerData['docId'])
                  .collection('alinan_urunler')
                  .where('urunID', isEqualTo: productId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Bu ürün için işlem bulunamadı.');
                }

                final transactions = snapshot.data!.docs;

                return SingleChildScrollView( // Burada `ListView` yerine `SingleChildScrollView` kullanıyoruz
                  child: Column(
                    children: transactions.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // Tarihi formatlamak için DateFormat kullanıyoruz
                      final formattedDate = DateFormat('dd/MM/yyyy').format((data['tarih'] as Timestamp).toDate());

                      return ListTile(
                        title: Text('Adet: ${data['adet']}'),
                        subtitle: Text('İşlem Türü: ${data['islemTuru']}'),
                        trailing: Text(
                          formattedDate,  // Formatlanmış tarihi burada kullanıyoruz
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  // Stok ekleme/çıkarma pop-up
  void _showStockDialog(BuildContext context, {required bool isAdding}) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController paymentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isAdding ? 'Ürün/Stok Ekle' : 'Ürün/Stok Çıkar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(widget.customerData['pazID'])
                        .collection('stoklar')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('Mevcut stok bulunamadı.');
                      }
                      final products = snapshot.data!.docs;

                      return DropdownButton<String>(
                        value: selectedProductId,
                        hint: const Text('Ürün Seçin'),
                        isExpanded: true,
                        items: products.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text('${data['name']} (Stok: ${data['stok']})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedProductId = value;
                          });
                        },
                      );
                    },
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Adet'),
                    keyboardType: TextInputType.number,
                  ),
                  if (isAdding)
                    TextField(
                      controller: paymentController,
                      decoration: const InputDecoration(labelText: 'Alınan Para'),
                      keyboardType: TextInputType.number,
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedProductId != null && quantityController.text.isNotEmpty) {
                      final int quantity = int.tryParse(quantityController.text) ?? 0;
                      final num receivedAmount = isAdding
                          ? int.tryParse(paymentController.text) ?? 0
                          : 0;

                      if (quantity > 0) {
                        final productRef = _firestore
                            .collection('users')
                            .doc(widget.customerData['pazID'])
                            .collection('stoklar')
                            .doc(selectedProductId);

                        final productRef2 = _firestore
                            .collection('users')
                            .doc(widget.customerData['docId'])
                            .collection('stoklar')
                            .doc(selectedProductId);

                        final productData = await productRef.get();
                        if (productData.exists) {
                          final data = productData.data() as Map<String, dynamic>;
                          final num unitPrice = data['fiyat']; // Ürün fiyatı
                          final String productName = data['name'];
                          final String barcode = data['barcode'];
                          final num totalAmount = unitPrice * quantity; // Toplam tutar
                          final num debt = totalAmount - receivedAmount; // Borç

                          await _firestore.runTransaction((transaction) async {
                            // Tüm okumalar
                            final productSnapshot = await transaction.get(productRef);
                            final productSnapshot2 = await transaction.get(productRef2);

                            if (productSnapshot.exists) {
                              final currentStock = productSnapshot['stok'];
                              final newStock = isAdding ? currentStock - quantity : currentStock + quantity;

                              if (newStock >= 0) {
                                // İlk ürün için stok güncellemesi
                                transaction.update(productRef, {'stok': newStock});

                                await _firestore
                                    .collection('users')
                                    .doc(widget.customerData['docId'])
                                    .collection('alinan_urunler')
                                    .add({
                                  'urunID': selectedProductId,
                                  'name': productName,
                                  'adet': quantity,
                                  'islemTuru': isAdding ? 'Dağıtım' : 'Satış',
                                  'tarih': DateTime.now(),
                                  'pazID': widget.customerData["pazID"],
                                });

                                // İkinci ürün için kontrol ve güncelleme
                                if (productSnapshot2.exists) {
                                  final currentStock2 = productSnapshot2['stok'];
                                  transaction.update(productRef2, {'stok': currentStock2 + quantity});
                                } else {
                                  transaction.set(productRef2, {
                                    'name': productName,
                                    'stok': quantity,
                                    'pazID': widget.customerData["pazID"],
                                    'barcode': barcode,
                                  });
                                }

                                // Diğer eklemeler
                                if (isAdding) {
                                  await _firestore
                                      .collection('users')
                                      .doc(widget.customerData['pazID'])
                                      .collection('verilen_urunler')
                                      .add({
                                    'urunID': selectedProductId,
                                    'name': productName,
                                    'adet': quantity,
                                    'tarih': DateTime.now(),
                                    'musteriID': widget.customerData["docId"],
                                    'alinmasi_gereken': totalAmount,
                                    'alinan_para': receivedAmount,
                                    'borc': debt,
                                  });
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Yetersiz stok.')),
                                );
                              }
                            }
                          });

                          Navigator.pop(context);
                        }
                      }
                    }
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerData['name'] ?? 'Müşteri Profili'),
        leading: photoBytes != null
            ? CircleAvatar(
          radius: 24, // Avatar boyutunu büyütüyoruz
          backgroundImage: MemoryImage(photoBytes!),
        )
            : const Icon(Icons.account_circle, size: 40), // Varsayılan ikon
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.customerData['docId'])
                  .collection('stoklar')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Stokta ürün bulunamadı.'));
                }

                final productList = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'productId': doc.id,
                    'productName': data['name'] ?? 'Bilinmeyen Ürün',
                    'productStock': data['stok'] ?? 0,
                  };
                }).toList();

                return ListView.builder(
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final product = productList[index];
                    final productName = product['productName'];
                    final productStock = product['productStock'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4, // Kartın gölgesini artırıyoruz
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Yuvarlatılmış köşeler
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(productName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        subtitle: Text('Stok: $productStock', style: TextStyle(fontSize: 16)),
                        onTap: () => _showProductDetailsPopup(
                          context,
                          product['productId'],
                          productName,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Butonları düzenlemek için bir Row kullanıyoruz
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _showStockDialog(context, isAdding: true),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12), backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Yeşil renk
                  ),
                  child: Text('Stok Ekle'),
                ),
                ElevatedButton(
                  onPressed: () => _showStockDialog(context, isAdding: false),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12), backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Kırmızı renk
                  ),
                  child: Text('Stok Çıkar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
