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
      title: 'Dürt Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B1C36),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF9E07F),
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- Arka plan SVG (assets/svg/background_main.svg gelecek) ---
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/svg/background_main.svg',
            fit: BoxFit.cover,
          ),
        ),

        // --- İçerik ---
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Üst bilgi: avatar + isim + puan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // avatar çerçevesi
                    SvgPicture.asset(
                      'assets/svg/avatar_frame_blue.svg',
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Okan Demir.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // puan ikonu
                    SvgPicture.asset(
                      'assets/svg/icon_point.svg',
                      height: 22,
                      width: 22,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '14,11K',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Başlık
              Text('Dürt', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const Spacer(),

              // Butonlar (SVG arkaplan + yazı)
              SvgButton(
                asset: 'assets/svg/button_play.svg',
                label: 'Hemen Oyna',
                textColor: const Color(0xFF2C2B2A),
                onTap: () {},
              ),
              const SizedBox(height: 14),
              SvgButton(
                asset: 'assets/svg/button_room_create.svg',
                label: 'Oda Aç',
                onTap: () {},
              ),
              const SizedBox(height: 14),
              SvgButton(
                asset: 'assets/svg/button_room_find.svg',
                label: 'Oda Ara',
                onTap: () {},
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ],
    );
  }
}

class SvgButton extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  const SvgButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            asset,
            width: MediaQuery.of(context).size.width * 0.85,
            height: 72,
            fit: BoxFit.fill,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: textColor,
                  shadows: const [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
