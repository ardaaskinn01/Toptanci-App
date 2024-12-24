import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UrunDialog extends StatefulWidget {
  final String isim;
  final dynamic fiyat;
  final dynamic stok;
  final dynamic barcode;
  final String urunId;

  const UrunDialog({
    Key? key,
    required this.isim,
    required this.fiyat,
    required this.stok,
    required this.barcode,
    required this.urunId,
  }) : super(key: key);

  @override
  _UrunDialogState createState() => _UrunDialogState();
}

class _UrunDialogState extends State<UrunDialog> {
  int _stokDegeri = 0;
  double _fiyatDegeri = 0.0;
  String _barcodeDegeri = '';

  Future<void> stokGuncelle(String urunId, int degisim) async {
    final urunRef = FirebaseFirestore.instance.collection('urunler').doc(urunId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(urunRef);
      if (snapshot.exists) {
        final mevcutStok = snapshot['stok'] ?? 0;
        transaction.update(urunRef, {'stok': mevcutStok + degisim});
      }
    });
  }

  Future<void> fiyatGuncelle(String urunId, double fiyat) async {
    final urunRef = FirebaseFirestore.instance.collection('urunler').doc(urunId);
    await urunRef.update({'fiyat': fiyat});
  }

  Stream<List<Map<String, dynamic>>> getPazarlamacilar(String urunId) async* {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'pazarlama')
        .get();

    final pazarlamacilar = await Future.wait(querySnapshot.docs.map((doc) async {
      final querySnapshot2 = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .collection('stoklar')
          .doc(urunId)
          .get();

      if (querySnapshot2.exists) {
        final stok = querySnapshot2['stok'];
        return {
          'name': doc['name'],
          'stok': stok,
        };
      } else {
        return null;
      }
    }).toList());

    final filteredPazarlamacilar = pazarlamacilar.whereType<Map<String, dynamic>>().toList();
    yield filteredPazarlamacilar;
  }

  @override
  Widget build(BuildContext context) {
    final double ekranYuksekligi = MediaQuery.of(context).size.height;

    return Container(
      height: ekranYuksekligi * 0.8,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              widget.isim,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            // Stok için artır/azalt
            _buildStokInputRow(),
            const SizedBox(height: 20),
            // Fiyat için güncelle
            _buildFiyatInputRow(),
            const SizedBox(height: 20),
            const Text('Pazarlamacılar:', style: TextStyle(fontSize: 18)),
            _buildPazarlamaciList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStokInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              _stokDegeri = int.tryParse(value) ?? 0;
            },
            decoration: InputDecoration(
              labelText: "Stok",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => stokGuncelle(widget.urunId, _stokDegeri),
          icon: const Icon(Icons.add, color: Colors.green),
          label: const Text("Artır", style: TextStyle(color: Colors.green),),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => stokGuncelle(widget.urunId, -_stokDegeri),
          icon: const Icon(Icons.remove, color: Colors.red),
          label: const Text("Azalt", style: TextStyle(color: Colors.red),),
        ),
      ],
    );
  }

  Widget _buildFiyatInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              _fiyatDegeri = double.tryParse(value) ?? 0.0;
            },
            decoration: InputDecoration(
              labelText: "Fiyat",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => fiyatGuncelle(widget.urunId, _fiyatDegeri),
          child: const Text("Güncelle", style: TextStyle(color: Colors.blue),),
        ),
      ],
    );
  }

  Widget _buildPazarlamaciList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getPazarlamacilar(widget.urunId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final pazarlamacilar = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: pazarlamacilar.length,
          itemBuilder: (context, index) {
            final pazarlamaci = pazarlamacilar[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(pazarlamaci['name']),
              subtitle: Text('Elindeki stok: ${pazarlamaci['stok']}'),
            );
          },
        );
      },
    );
  }
}
