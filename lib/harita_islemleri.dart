import 'dart:typed_data';
import 'dart:convert'; // Base64 çözümleme için
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'musteri_profil.dart';

class HaritaIslemleri extends StatefulWidget {
  const HaritaIslemleri({super.key});

  @override
  State<HaritaIslemleri> createState() => _HaritaIslemleriState();
}

class _HaritaIslemleriState extends State<HaritaIslemleri> {
  LatLng? _targetLocation;
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcıları almak için Firestore'dan veri çekme
  Future<List<Map<String, dynamic>>> _getUsers() async {
    try {
      var querySnapshot = await _firestore.collection('users').where('pazID', isEqualTo: _auth.currentUser?.uid).get();
      return querySnapshot.docs.map((doc) {
        var data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error getting users: $e");
      return [];
    }
  }

  // Fotoğraf verisini çözme
  Uint8List? _decodePhotoData(dynamic photoData) {
    if (photoData is List<dynamic>) {
      // Veriyi List<int> türüne dönüştür
      return Uint8List.fromList(List<int>.from(photoData));
    } else if (photoData is String) {
      // Eğer Base64 string ise, çöz
      return base64Decode(photoData);
    }
    print("Geçersiz fotoğraf verisi");
    return null;
  }

  // Firestore'da location verisini güncelleme
  Future<void> _updateLocation(String userId, LatLng location) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'location': GeoPoint(location.latitude, location.longitude),
      });
      print("Location updated for user: $userId");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  // Konum seçildiğinde gösterilecek popup
  void _showLocationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Buraya müşteri eklemek ister misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hayır'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                List<Map<String, dynamic>> users = await _getUsers();
                if (users.isNotEmpty) {
                  _showUserDropdown(users);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kullanıcı bulunamadı.")));
                }
              },
              child: Text('Evet'),
            ),
          ],
        );
      },
    );
  }

  // Dropdown menüsünü göstermek için pop-up
  void _showUserDropdown(List<Map<String, dynamic>> users) {
    String? selectedUserId;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Bir kullanıcı seçin'),
              content: DropdownButton<String>(
                isExpanded: true,
                hint: Text("Kullanıcı Seçin"),
                value: selectedUserId,
                onChanged: (newValue) {
                  setState(() {
                    selectedUserId = newValue;
                  });
                },
                items: users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['docId'],
                    child: Text(user['name']),
                  );
                }).toList(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedUserId != null) {
                      _updateLocation(selectedUserId!, _targetLocation!);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lütfen bir kullanıcı seçin.")));
                    }
                  },
                  child: Text('Kaydet'),
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
      appBar: AppBar(title: Text("Kullanıcı Konumları")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(38.9637, 35.2433),
              zoom: 6.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _targetLocation = point;
                });
                _showLocationPopup();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Kullanıcı bulunamadı.'));
                  }
                  final users = snapshot.data!;
                  return MarkerLayer(
                    markers: users.map((user) {
                      final location = user['location'];
                      if (location == null) return null;

                      // Fotoğraf verisini çöz
                      final photoData = user['photo'];
                      final photoBytes = _decodePhotoData(photoData);

                      return Marker(
                        point: LatLng(location.latitude, location.longitude),
                        builder: (context) => GestureDetector(
                          onTap: () {
                            // Tıklanan avatarın bilgilerini geçiyoruz
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerProfileScreen(customerData: user),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,  // Stack'in taşan kısmı görünmesin
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photoBytes != null
                                    ? MemoryImage(photoBytes)
                                    : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                              ),
                              // Kullanıcı ismi ve ok simgesi
                              Positioned(
                                top: -30, // İsim ve ok, avatarın üstünde biraz yukarıda olacak
                                child: Column(
                                  children: [
                                    Text(
                                      user['name'] ?? 'No Name',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Icon(Icons.arrow_upward, size: 16, color: Colors.blue), // Ok simgesi
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).whereType<Marker>().toList(),
                  );
                },
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _mapController.move(_mapController.center, _mapController.zoom + 1);
                  },
                  child: Icon(Icons.zoom_in),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    _mapController.move(_mapController.center, _mapController.zoom - 1);
                  },
                  child: Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
