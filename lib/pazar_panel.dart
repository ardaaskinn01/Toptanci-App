import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toptanci/harita_islemleri.dart';
import 'hareketler.dart';
import 'main.dart';
import 'musteri_profil.dart';
import 'urun_hareketleri.dart'; // Yeni müşteri profil ekranı
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class PazarPanel extends StatefulWidget {
  const PazarPanel({Key? key}) : super(key: key);

  @override
  _PazarPanelState createState() => _PazarPanelState();
}

class _PazarPanelState extends State<PazarPanel> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          setState(() {
            currentUserName = userDoc.data()?['name'] ?? 'Anonim';
          });
        }
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgisi alınırken hata: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    // Kullanıcıyı login sayfasına yönlendir
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Login sayfanızın ismini buraya ekleyin
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hoşgeldin $currentUserName"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Hareketler'), // Yeni sekme
            Tab(icon: Icon(Icons.inventory), text: 'Ürünlerim'),
            Tab(icon: Icon(Icons.list), text: 'Müşterilerim'),
            Tab(icon: Icon(Icons.map), text: 'Harita'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Hareketler sekmesi
          HareketlerScreen(userId: _auth.currentUser!.uid),
          // Ürünlerim Sekmesi
          ProductMovementsScreen(),
          // Müşteri Listesi Sekmesi
          Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'musteri')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Kayıtlı müşteri bulunamadı.'));
                  }

                  final customers = snapshot.data!.docs.map((doc) {
                    return {
                      'docId': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    };
                  }).toList();

                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: customer['photo'] != null
                              ? CircleAvatar(
                            backgroundImage: MemoryImage(base64Decode(customer['photo'])),
                          )
                              : const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(customer['name'] ?? 'İsim Yok', style: TextStyle(fontWeight: FontWeight.bold),),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kullanıcı Adı: ${customer['id']}'),
                              Text('Şifre: ${customer['password']}'),
                              Text('Telefon: ${customer['phone'] ?? 'Kayıtlı Değil'}'), // Telefon numarası eklendi
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerProfileScreen(customerData: customer),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _showAddCustomerDialog(context),
                  child: const Icon(Icons.add),
                  tooltip: 'Müşteri Ekle',
                ),
              ),
            ],
          ),
          // Harita Sekmesi
          HaritaIslemleri(),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();  // Telefon numarası için controller

    String? _imageBase64;  // Fotoğrafı base64 formatında saklamak için değişken
    final ImagePicker _picker = ImagePicker();

    // Fotoğraf seçme fonksiyonu
    Future<void> _pickImage() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        _imageBase64 = base64Encode(bytes);  // Fotoğrafı base64 formatında sakla
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Müşteri Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'İsim'),
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,  // Telefon numarası için uygun klavye türü
              ),
              ElevatedButton(
                onPressed: _pickImage,  // Fotoğraf seçme işlemi
                child: const Text('Fotoğraf Seç'),
              ),
              if (_imageBase64 != null)
                Image.memory(
                  base64Decode(_imageBase64!),
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
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
                final String name = nameController.text.trim();
                final String id = idController.text.trim();
                final String password = passwordController.text.trim();
                final String phone = phoneController.text.trim();

                if (name.isNotEmpty && id.isNotEmpty && password.isNotEmpty && phone.isNotEmpty) {
                  try {
                    // Firebase Authentication ile kullanıcı kaydı
                    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
                      email: '$id@example.com',  // ID'yi e-posta olarak kullanıyoruz
                      password: password,
                    );

                    // Müşteri bilgilerini Firestore'a kaydetme
                    await _firestore.collection('users').doc(userCredential.user?.uid).set({
                      'name': name,
                      'id': id,
                      'password': password,
                      'phone': phone,  // Telefon numarasını kaydediyoruz
                      'role': 'musteri',
                      'photo': _imageBase64,  // Fotoğraf base64 olarak kaydediliyor
                      'pazID': _auth.currentUser?.uid,
                    });

                    await _auth.signOut();

                    // Kullanıcı kaydı başarılıysa, dialogu kapatıyoruz
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Müşteri başarıyla eklendi!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Müşteri eklenirken hata: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }
}
