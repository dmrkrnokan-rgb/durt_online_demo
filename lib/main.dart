import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const DurtApp());
}

class DurtApp extends StatelessWidget {
  const DurtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dürt Online Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MainMenuScreen()),
            );
          },
          child: const Text("Offline Oyna"),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ana Menü")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              child: const Text("Ayarlar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TableScreen()),
                );
              },
              child: const Text("Masa (Test)"),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: const Center(child: Text("Ayarlar buraya gelecek")),
    );
  }
}

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Oyun Masası")),
      body: Stack(
        children: [
          // Masa arka plan
          Positioned.fill(
            child: SvgPicture.asset(
              "assets/tables/background_main.svg",
              fit: BoxFit.cover,
            ),
          ),
          // Ortada DÜRT butonu
          Center(
            child: SvgPicture.asset(
              "assets/ui/button_durt.svg",
              width: 160,
              height: 70,
            ),
          ),
        ],
      ),
    );
  }
}
