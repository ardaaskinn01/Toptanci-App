import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:toptanci/pazar_panel.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'mudur_panel.dart';
import 'musteri_panel.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FirebaseAuth.instance.currentUser == null
          ? LoginScreen() // Eğer kullanıcı yoksa login ekranına yönlendir
          : FutureBuilder<String?>(
        future: _getUserRole(), // Kullanıcı rolünü almak için asenkron işlem
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.blueAccent, // Yükleme sırasında arka plan rengi
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Veriler Yükleniyor...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
          final user = FirebaseAuth.instance.currentUser;
          if (snapshot.hasData) {
            final role = snapshot.data;
            if (role == 'mudur') {
              return MudurPanel(id: user!.uid); // Admin ise admin paneline yönlendir
            } else if (role == 'pazarlama') {
              return PazarPanel(id: user!.uid); // User ise user paneline yönlendir
            }
            else {
              return MusteriPanel();
            }
          }

          // Eğer rol alınamazsa login ekranına yönlendir
          return LoginScreen();
        },
      ),
    );
  }

  // Kullanıcı rolünü Firestore'dan alacak fonksiyon
  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        return userDoc.data()?['role']; // Kullanıcı rolünü döndürüyoruz
      } catch (e) {
        print("Rol alınırken hata oluştu: $e");
        return null; // Rol alınamadığında null döndür
      }
    }
    return null; // Kullanıcı yoksa null döndür
  }
}



class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Müdür kaydı oluşturmak için kullanılacak TextEditingController'lar
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController managerUsernameController = TextEditingController();
  final TextEditingController managerPasswordController = TextEditingController();

  // Kullanıcı girişi yapma fonksiyonu
  Future<void> loginUser(String username, String password, BuildContext context) async {
    try {
      final email = '$username@example.com';

      // Firestore'dan kullanıcı adı kontrolü
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showSnackBar(context, "Kullanıcı bulunamadı. Bilgileri kontrol edin.");
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final storedPassword = userDoc.data()['password'];

      if (storedPassword != password) {
        _showSnackBar(context, "Şifre yanlış. Lütfen tekrar deneyin.");
        return;
      }

      final userId = userDoc.id;
      final role = userDoc.data()['role'];
      final name = userDoc.data()['name'];
      var mudurID = '';// 'name' alanını buradan alıyoruz.
      if (role == "pazarlama") {
        mudurID = userDoc.data()['mudurID'];
      }

      // Firebase Auth kontrolü
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (_) {
        // Eğer kullanıcı Auth'ta yoksa yeni kullanıcı oluştur
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final authUid = userCredential.user!.uid;

      // Eğer Auth UID ve Firestore doküman ID'si eşleşmiyorsa, eski dokümanı silip yeni doküman oluştur
      if (authUid != userId) {
        // Eski dokümanı sil
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();

        // Yeni dokümanı oluştur
        await FirebaseFirestore.instance.collection('users').doc(authUid).set({
          'name': name,  // Burada 'name' değerini kullanıyoruz
          'id': username,
          'password': password,
          'role': role,
          'deviceToken': '',
          'mudurID': mudurID,
        });
      }

      // Cihaz token'ını kaydet
      final token = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance.collection('users').doc(authUid).update({
        'deviceToken': token,
      });

      // Kullanıcı rolüne göre yönlendirme
      if (role == 'mudur') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MudurPanel(id: authUid)),
        );
      } else if (role == 'pazarlama') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PazarPanel(id: authUid)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MusteriPanel()),
        );
      }
    } catch (e) {
      // Genel hata mesajı
      print("Hata: $e");
      _showSnackBar(context, 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyiniz.');
    }
  }


  // Müdür kaydı oluşturma fonksiyonu
  Future<void> createManager(BuildContext context) async {
    final name = managerNameController.text.trim();
    final username = managerUsernameController.text.trim();
    final password = managerPasswordController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      _showSnackBar(context, "Tüm alanları doldurun.");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'id': username,
        'password': password,
        'role': 'mudur',
      });

      _showSnackBar(context, "Müdür kaydı başarıyla oluşturuldu.");
      managerNameController.clear();
      managerUsernameController.clear();
      managerPasswordController.clear();
    } catch (e) {
      print("Müdür kaydı oluşturulurken hata: $e");
      _showSnackBar(context, "Bir hata oluştu. Lütfen tekrar deneyin.");
    }
  }

  // SnackBar göstermek için kullanılan fonksiyon
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEAE8E8), // Hafif gri arka plan
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 100),

                // Kullanıcı adı girişi
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 25),

                // Şifre girişi
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 32),

                // Giriş yap butonu
                ElevatedButton(
                  onPressed: () => loginUser(usernameController.text, passwordController.text, context),
                  child: Text('Giriş Yap', style: TextStyle(color: Colors.black),),
                ),

                SizedBox(height: 20),

                // Müdür kaydı oluştur butonu
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Müdür Kaydı Oluştur', style: TextStyle(color: Colors.black),),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: managerNameController,
                                decoration: InputDecoration(labelText: 'Ad Soyad'),
                              ),
                              TextField(
                                controller: managerUsernameController,
                                decoration: InputDecoration(labelText: 'Kullanıcı Adı'),
                              ),
                              TextField(
                                controller: managerPasswordController,
                                decoration: InputDecoration(labelText: 'Şifre'),
                                obscureText: true,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('İptal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                createManager(context);
                                Navigator.pop(context);
                              },
                              child: Text('Kaydet'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Müdür Kaydı Oluştur', style: TextStyle(color: Colors.black),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

