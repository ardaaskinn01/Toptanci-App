import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'stock_popup.dart';

class MusteriPanel extends StatefulWidget {
  const MusteriPanel({Key? key}) : super(key: key);

  @override
  _MusteriPanelState createState() => _MusteriPanelState();
}

class _MusteriPanelState extends State<MusteriPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  // Kamera izni kontrol ve istek fonksiyonu
  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  // Barkod tarama ve stok güncelleme fonksiyonu
  Future<void> _scanBarcode() async {
    await _requestCameraPermission();

    try {
      var scanResult = await BarcodeScanner.scan();
      setState(() {
        _scannedBarcode = scanResult.rawContent.isNotEmpty
            ? scanResult.rawContent
            : "Tarama Başarısız";
      });

      if (_scannedBarcode != "Tarama Başarısız") {
        print("Taranan Barkod: $_scannedBarcode");
        await _updateStock(_scannedBarcode);
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

      var stoklarSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stoklar')
          .where('barcode', isEqualTo: scannedBarcode)
          .get();

      if (stoklarSnapshot.docs.isNotEmpty) {
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
        backgroundColor: Colors.teal,
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
              ElevatedButton(
                onPressed: _scanBarcode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.teal.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                child: Text(
                  'Barkod Tara',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Sonuç: $_scannedBarcode',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return StockPopup();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                child: Text(
                  'Stokları İncele',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
