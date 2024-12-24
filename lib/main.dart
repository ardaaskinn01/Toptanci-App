import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:toptanci/pazar_panel.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

          if (snapshot.hasData) {
            final role = snapshot.data;
            if (role == 'mudur') {
              return MudurPanel(); // Admin ise admin paneline yönlendir
            } else if (role == 'pazarlama') {
              return PazarPanel(); // User ise user paneline yönlendir
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

  // Kullanıcı girişi yapma fonksiyonu
  Future<void> loginUser(String username, String password, BuildContext context) async {
    try {
      final email = '$username@example.com';

      // Firebase ile giriş yapma işlemi
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı başarılı şekilde giriş yaptıysa
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore'dan kullanıcı rolünü alıyoruz
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'];
        final userId = user.uid;

        // Rol kontrolü yapıyoruz
        if (role == 'mudur') {
          try {
            final token = await FirebaseMessaging.instance.getToken();
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'deviceToken': token,
            });
          }
          catch (e){
            print("HATA $e");
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MudurPanel()),
          );
        } else if (role == 'pazarlama') {
          try {
            final token = await FirebaseMessaging.instance.getToken();
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'deviceToken': token,
            });
          }
          catch (e){
            print("HATA $e");
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PazarPanel()),
          );
        }
        else {
          try {
            final token = await FirebaseMessaging.instance.getToken();
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'deviceToken': token,
            });
          }
          catch (e){
            print("HATA $e");
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MusteriPanel()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // FirebaseAuthException hatalarında kullanıcıya basit bir mesaj gösteriyoruz
      _showSnackBar(context, "Bilgiler Yanlış. Tekrar Deneyiniz.");
    } catch (e) {
      // Diğer hatalar için genel bir mesaj
      _showSnackBar(context, 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyiniz.');
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
                // Başlık
                Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8805),
                      fontStyle: FontStyle.italic
                  ),
                ),
                SizedBox(height: 100), // Başlık ile giriş formu arasındaki boşluk

                // Kullanıcı adı girişi
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF08FFFF), width: 2),
                    ),
                    prefixIcon: Icon(Icons.person, color: Color(0xFF08FFFF)),
                  ),
                ),
                SizedBox(height: 25),

                // Şifre girişi
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF08FFFF), width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF08FFFF)),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 32),

                // Giriş butonu
                ElevatedButton(
                  onPressed: () =>
                      loginUser(usernameController.text, passwordController.text, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF8805), // Buton rengi
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Giriş Yap', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
