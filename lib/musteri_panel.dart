import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toptanci/main.dart';
import 'stock_popup.dart'; // Popup için import
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importu

class MusteriPanel extends StatefulWidget {
  const MusteriPanel({Key? key}) : super(key: key);

  @override
  _MusteriPanelState createState() => _MusteriPanelState();
}

class _MusteriPanelState extends State<MusteriPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  String _scannedBarcode = "Henüz taranmadı";

  // Çıkış yapma fonksiyonu
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print("Çıkış yaparken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılırken hata oluştu')),
      );
    }
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      if (await Permission.camera.request().isGranted) {
        print('Kamera izni verildi');
      } else {
        print('Kamera izni reddedildi');
      }
    } else if (status.isGranted) {
      print('Kamera izni zaten verilmiş');
    }
  }

  Future<void> _scanBarcode() async {
    await _requestCameraPermission();
    try {
      String scannedBarcode = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666",
        "İptal",
        true,
        ScanMode.BARCODE,
      );

      if (scannedBarcode != "-1") {
        setState(() {
          _scannedBarcode = scannedBarcode;
        });
        print("Taranan Barkod: $scannedBarcode");

        // Taranan barkod numarasını kullanarak stokları güncelle
        _updateStock(scannedBarcode);
      } else {
        print("Barkod tarama iptal edildi.");
      }
    } catch (e) {
      print("Barkod tarama sırasında hata oluştu: $e");
    }
  }

  // Stokları güncelleyen fonksiyon
  Future<void> _updateStock(String scannedBarcode) async {
    try {
      var userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('Kullanıcı bilgisi bulunamadı.');
        return;
      }

      // Kullanıcıya ait stoklar koleksiyonunda ürün arıyoruz
      var stoklarSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stoklar')
          .where('barcode', isEqualTo: scannedBarcode) // Barkod ile eşleşen ürün
          .get();

      if (stoklarSnapshot.docs.isNotEmpty) {
        // Barkod eşleşti, stok miktarını 1 azaltalım
        var docRef = stoklarSnapshot.docs.first.reference;
        var docSnapshot = await docRef.get();

        var currentStock = docSnapshot['stok'];
        if (currentStock > 0) {
          await docRef.update({'stok': currentStock - 1});
          print('Stok güncellendi: ${currentStock - 1}');
        } else {
          print('Stok zaten sıfır.');
        }
      } else {
        print('Barkod ile eşleşen ürün bulunamadı.');
      }
    } catch (e) {
      print('Stok güncelleme sırasında hata oluştu: $e');
    }
  }

  // Stokları incelemek için pop-up açma fonksiyonu
  void _showStockPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // İçeriğin kaydırılabilir olmasını sağlıyoruz
      builder: (BuildContext context) {
        return StockPopup(); // StockPopup widget'ını çağırıyoruz
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Müşteri Paneli',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 28),
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.teal, // Şık bir renk tonu
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Barkod tarama butonu
              ElevatedButton(
                onPressed: _scanBarcode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16), backgroundColor: Colors.teal.shade600, // Buton rengi
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                child: Text(
                  'Barkod Tara',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
              SizedBox(height: 30),
              // Barkod sonuç metni
              Text(
                'Sonuç: $_scannedBarcode',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
              SizedBox(height: 30),
              // Stokları İncele butonu
              ElevatedButton(
                onPressed: _showStockPopup,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16), backgroundColor: Colors.orange, // Buton rengi
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                child: Text(
                  'Stokları İncele',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
