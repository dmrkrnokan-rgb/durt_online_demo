import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const DurtApp());

class DurtApp extends StatelessWidget {
  const DurtApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dürt (Offline)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0E1A2A),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const TableScreen(),
    );
  }
}

/* =============================== OYUN DURUMU =============================== */

const suits = ['Spades','Hearts','Diamonds','Clubs'];
const ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
const rankScore = {
  'A': 15, 'K': 13, 'Q': 12, 'J': 11,
  '10': 10, '9':9, '8':8, '7':7, '6':6, '5':5, '4':4, '3':3, '2':2,
};

String cardPath(String suit, String rank) => 'assets/cards/${suit}_$rank.svg';

({String suit, String rank}) parseCard(String path){
  // assets/cards/Spades_A.svg
  final name = path.split('/').last.split('.').first; // Spades_A
  final parts = name.split('_');
  return (suit: parts[0], rank: parts[1]);
}

bool canPlay(String top, String candidate){
  final a = parseCard(top);
  final b = parseCard(candidate);
  return a.suit == b.suit || a.rank == b.rank;
}

/* =============================== MASA EKRANI =============================== */

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});
  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> with TickerProviderStateMixin {
  final List<List<String>> hands = [[],[],[],[]];
  late List<String> deck;
  String? topCard; // masadaki en üst
  int turn = 0;    // 0 = sen, 1 üst, 2 sol, 3 sağ
  bool durtMode = false;
  final List<int> durtPenalty = [0,0,0,0]; // oyuncu başına +10

  // Merkezde animasyon
  late AnimationController centerAnim;
  late Animation<double> scaleAnim;
  late Animation<double> fadeAnim;

  // Bot oynama sırası kilidi
  bool _botsRunning = false;

  @override
  void initState() {
    super.initState();
    centerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    scaleAnim = CurvedAnimation(parent: centerAnim, curve: Curves.easeOutBack);
    fadeAnim  = CurvedAnimation(parent: centerAnim, curve: Curves.easeOutCubic);
    _newHand();
  }

  @override
  void dispose() {
    centerAnim.dispose();
    super.dispose();
  }

  void _newHand() {
    // deste oluştur + karıştır
    deck = [
      for (final s in suits) for (final r in ranks) cardPath(s, r)
    ]..shuffle(math.Random());
    // dağıt
    for (final h in hands) { h.clear(); }
    for (int i=0;i<52;i++){ hands[i%4].add(deck[i]); }
    // ilk top rastgele kendi elinden olsun (kural gereği ilk atış)
    topCard = hands[0].removeLast();
    turn = 1; // ilk hamle üst oyuncuya verelim
    durtPenalty.setAll(0, [0,0,0,0]);
    centerAnim.forward(from: 0);
    _scheduleBots();
    setState((){});
  }

  void _scheduleBots() {
    if (_botsRunning) return;
    _botsRunning = true;

    Future<void>.delayed(const Duration(milliseconds: 400), () async {
      while (turn != 0 && mounted && !_handEnded()) {
        await _botPlay(turn);
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      _botsRunning = false;
      if (_handEnded()) _showScoreModal();
    });
  }

  bool _handEnded(){
    // biri biterse el biter
    for (int i=0;i<4;i++){ if (hands[i].isEmpty) return true; }
    return false;
  }

  Future<void> _botPlay(int idx) async {
    final playable = hands[idx].where((c)=> canPlay(topCard!, c)).toList();
    String chosen;
    if (playable.isNotEmpty) {
      chosen = playable.first; // basit bot mantığı: ilk uygun kart
    } else {
      // DÜRT: herhangi bir kart at, +10 ceza
      chosen = hands[idx].first;
      durtPenalty[idx] += 10;
    }
    hands[idx].remove(chosen);
    await _animateCenter(chosen);
    turn = (turn+1) % 4;
    setState((){});
  }

  Future<void> _animateCenter(String played) async {
    setState(()=> topCard = played);
    centerAnim.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _playerPlay(String card) async {
    if (turn != 0 || topCard == null) return;
    final ok = canPlay(topCard!, card);
    if (!ok && !durtMode) {
      _toast('Karta uymuyor! DÜRT aç veya uygun kart seç.');
      return;
    }
    if (!ok && durtMode) {
      durtPenalty[0] += 10;
    }
    hands[0].remove(card);
    await _animateCenter(card);
    turn = 1;
    setState((){});
    if (_handEnded()) {
      _showScoreModal();
    } else {
      _scheduleBots();
    }
  }

  void _toast(String msg){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1200))
    );
  }

  void _showScoreModal() {
    final scores = _calcScores();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF112233),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16,18,16,20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('E L  B İ T T İ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
              const SizedBox(height: 8),
              Row(
                children: List.generate(4, (i){
                  return Expanded(
                    child: _GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(i==0?'Sen':'Bot ${i}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('${scores[i] >=0? '+':''}${scores[i]} puan'),
                            if (durtPenalty[i]>0)
                              Text('(DÜRT cezası: +${durtPenalty[i]})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ()=> Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE2B28)),
                      onPressed: (){
                        Navigator.pop(context);
                        _newHand();
                      },
                      child: const Text('Yeni El'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      }
    );
  }

  List<int> _calcScores(){
    // Bitiren: -100, diğerleri: elde kalan kart toplamı + DÜRT
    final finisher = List.generate(4, (i)=> hands[i].isEmpty ? i : -1).firstWhere((x)=>x!=-1, orElse: ()=> -1);
    final scores = <int>[0,0,0,0];
    if (finisher != -1) scores[finisher] = -100;
    for (int i=0;i<4;i++){
      if (i==finisher) continue;
      int s = 0;
      for (final c in hands[i]) {
        final r = parseCard(c).rank;
        s += rankScore[r]!;
      }
      s += durtPenalty[i];
      scores[i] = s;
    }
    return scores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DÜRT • Offline Masa'),
        backgroundColor: const Color(0xFF12243A),
        actions: [
          IconButton(
            tooltip: 'Yeni El',
            onPressed: _newHand,
            icon: const Icon(Icons.shuffle, color: Color(0xFFD4AF37)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Masa arka planı
          Positioned.fill(
            child: _safeSvg('assets/tables/background_main.svg', fit: BoxFit.cover),
          ),
          // Üst oyuncu
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _OpponentRow(
                cards: hands[1],
                highlight: turn==1,
              ),
            ),
          ),
          // Sol ve sağ
          Align(
            alignment: Alignment.centerLeft,
            child: _OpponentColumn(cards: hands[2], highlight: turn==2),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _OpponentColumn(cards: hands[3], highlight: turn==3),
          ),
          // Merkezde en üst kart (animasyonlu)
          Center(
            child: AnimatedBuilder(
              animation: centerAnim,
              builder: (_, __){
                return Opacity(
                  opacity: fadeAnim.value,
                  child: Transform.scale(
                    scale: 0.86 + 0.14*scaleAnim.value,
                    child: SizedBox(
                      width: 120, height: 160,
                      child: topCard==null
                        ? const SizedBox.shrink()
                        : _safeSvg(topCard!, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),
          ),
          // Alt: senin elin
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomHandBar(
              cards: hands[0],
              onTap: _playerPlay,
              canPlayWith: topCard,
              durtMode: durtMode,
            ),
          ),
          // DÜRT anahtarı + buton
          Positioned(
            left: 16, bottom: 16,
            child: Row(
              children: [
                Switch(
                  value: durtMode,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (v){ setState(()=> durtMode = v); },
                ),
                const Text('DÜRT modu', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Positioned(
            right: 16, bottom: 12,
            child: SizedBox(
              width: 160, height: 70,
              child: _safeSvg('assets/ui/button_durt.svg', fit: BoxFit.contain),
            ),
          ),
          // Sıra göstergesi (avatar parlama)
          Positioned.fill(
            child: IgnorePointer(
              child: _TurnGlowOverlay(turn: turn),
            ),
          ),
        ],
      ),
    );
  }
}

/* =============================== WIDGETS =============================== */

class _OpponentRow extends StatelessWidget {
  final List<String> cards;
  final bool highlight;
  const _OpponentRow({required this.cards, required this.highlight});
  @override
  Widget build(BuildContext context) {
    return _GlowBox(
      glow: highlight,
      child: SizedBox(
        height: 82,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: List.generate(math.min(13, cards.length), (i){
            return _BackCardSmall();
          }),
        ),
      ),
    );
  }
}

class _OpponentColumn extends StatelessWidget {
  final List<String> cards;
  final bool highlight;
  const _OpponentColumn({required this.cards, required this.highlight});
  @override
  Widget build(BuildContext context) {
    return _GlowBox(
      glow: highlight,
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(math.min(13, cards.length), (i)=> const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: _BackCardSmall(),
          )),
        ),
      ),
    );
  }
}

class _BackCardSmall extends StatelessWidget {
  const _BackCardSmall();
  @override
  Widget build(BuildContext context) {
    // Kart arkasını göster (varsa svg), yoksa placeholder
    return SizedBox(
      width: 48, height: 66,
      child: _safeSvg('assets/backs/Kart_Arka_Kucuk.svg', fit: BoxFit.contain),
    );
  }
}

class _BottomHandBar extends StatelessWidget {
  final List<String> cards;
  final ValueChanged<String> onTap;
  final String? canPlayWith;
  final bool durtMode;

  const _BottomHandBar({
    super.key,
    required this.cards,
    required this.onTap,
    required this.canPlayWith,
    required this.durtMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: const BoxDecoration(
        color: Color(0xFF12243A),
        border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 2)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final path = cards[i];
          final playable = canPlayWith==null ? true : canPlay(canPlayWith!, path);
          final allowed = playable || durtMode;
          return Opacity(
            opacity: allowed ? 1.0 : 0.35,
            child: GestureDetector(
              onTap: allowed ? () => onTap(path) : null,
              child: SizedBox(
                width: 78, height: 110,
                child: _safeSvg(path, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TurnGlowOverlay extends StatelessWidget {
  final int turn;
  const _TurnGlowOverlay({required this.turn});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowPainter(turn),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final int turn;
  _GlowPainter(this.turn);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66FFD36A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 30);

    // 0: bottom center, 1: top center, 2: center left, 3: center right
    Offset center;
    switch (turn) {
      case 1: center = Offset(size.width/2, 56); break;
      case 2: center = Offset(56, size.height/2); break;
      case 3: center = Offset(size.width-56, size.height/2); break;
      default: center = Offset(size.width/2, size.height-56);
    }
    canvas.drawCircle(center, 44, paint);
  }
  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => oldDelegate.turn != turn;
}

class _GoldCard extends StatelessWidget {
  final Widget child;
  const _GoldCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17314F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
      ),
      child: child,
    );
  }
}

/* =============================== YARDIMCI =============================== */

Widget _safeSvg(String path, {BoxFit fit = BoxFit.contain}) {
  return SvgPicture.asset(
    path,
    fit: fit,
    placeholderBuilder: (_) => Container(
      color: const Color(0x11000000),
      child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white54)),
    ),
  );
}
