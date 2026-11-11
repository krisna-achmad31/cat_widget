import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/src/core/modules/model_viewer/model_viewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/legacy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1250, 420),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: "Couple Assistant - Screen Overlay Cat",
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setAlignment(Alignment.bottomCenter);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const CoupleAssistantOverlayApp());
}

class CoupleAssistantOverlayApp extends StatelessWidget {
  const CoupleAssistantOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couple Assistant Overlay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.nunito().fontFamily,
        useMaterial3: true,
      ),
      home: const DesktopCatOverlay(),
    );
  }
}

enum CatPosture {
  walking, // Kucing oren berjalan menggerakkan 4 kakinya melangkah
  sitting, // Kucing oren duduk manis menemani sambil menampilkan pesan
  sleeping // Kucing oren goler / tidur santai di layar desktop
}

class DesktopCatOverlay extends StatefulWidget {
  const DesktopCatOverlay({super.key});

  @override
  State<DesktopCatOverlay> createState() => _DesktopCatOverlayState();
}

class _DesktopCatOverlayState extends State<DesktopCatOverlay>
    with TickerProviderStateMixin {
  CatPosture _currentPosture = CatPosture.walking;

  // Animasi Berjalan melintasi layar
  late AnimationController _walkController;
  late Animation<double> _walkPosition;

  // Animasi Pernafasan Halus (Breathing Motion)
  late AnimationController _breatheController;

  // Partikel Hati
  final List<FloatingHeart> _hearts = [];
  late AnimationController _heartAnimController;

  // Timer transisi otomatis ke posisi istirahat
  Timer? _sleepTimer;

  // Data Chat Ayang
  bool _showBalloon = true;
  String _currentMessage =
      "Ayang: Semangat kerjanya yaa cintaku! Jangan lupa makan siang ❤️🐾";
  final String _senderName = "Ayang Cantik";
  DateTime _messageTime = DateTime.now();

  int _templateIndex = 0;
  final List<String> _sampleMessages = [
    "Ayang: Semangat kerjanya yaa cintaku! Jangan lupa makan siang ❤️🐾",
    "Ayang: Aku kangen bangeeet... Nanti malem videocall ya? 🥺✨",
    "Ayang: Udah minum air putih belum hari ini cintaku? 🥰💧",
    "Ayang: Lagi mikirin kamu terus nihh hihi... I love you! 💕",
    "Ayang: Pulang kerja langsung istirahat ya, jangan begadang 🌙✨",
    "Ayang: Mau nitip makanan apa nanti pas ketemu? 🍰🍓",
  ];

  @override
  void initState() {
    super.initState();

    // Cat walks from right (880.0) to left (180.0)
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    );

    _walkPosition = Tween<double>(begin: 880.0, end: 180.0).animate(
      CurvedAnimation(parent: _walkController, curve: Curves.easeInOutQuad),
    )..addListener(() {
        setState(() {});
      });

    // Breathing motion saat santai
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Hearts controller
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        setState(() {
          _hearts.removeWhere((h) => h.progress >= 1.0);
          for (var h in _hearts) {
            h.progress = _heartAnimController.value;
          }
        });
      });

    // Mulai jalan pertama kali saat pesan tiba
    Timer(const Duration(milliseconds: 600), () {
      _startWalkingWithMessage();
    });
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _walkController.dispose();
    _breatheController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  String _getModelPath(CatPosture posture) {
    // Selalu gunakan model kucing oyen asli
    return 'assets/models/bicolor_cat.glb';
  }

  void _triggerHearts(double x, double y) {
    final random = Random();
    _hearts.clear();
    for (int i = 0; i < 9; i++) {
      _hearts.add(FloatingHeart(
        startX: x + (random.nextDouble() * 80 - 40),
        startY: y,
        size: 16 + random.nextDouble() * 14,
        color: [
          const Color(0xFFFF5376),
          const Color(0xFFFF4D6D),
          const Color(0xFFFF758F),
          const Color(0xFFFF8FA3),
        ][random.nextInt(4)],
      ));
    }
    _heartAnimController.forward(from: 0.0);
  }

  /// Mulai aksi kucing oren melangkah mengantarkan pesan baru
  void _startWalkingWithMessage() {
    _sleepTimer?.cancel();

    setState(() {
      _currentPosture = CatPosture.walking;
      _showBalloon = true;
      _messageTime = DateTime.now();
    });

    _walkController.forward(from: 0.0).then((_) {
      if (mounted) {
        // Sampai di tujuan -> kucing duduk manis
        setState(() {
          _currentPosture = CatPosture.sitting;
        });

        _triggerHearts(_walkPosition.value + 150, 220);
        _scheduleSleepTransition();
      }
    });
  }

  void _scheduleSleepTransition() {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(const Duration(seconds: 14), () {
      if (mounted && _currentPosture == CatPosture.sitting) {
        setState(() {
          _currentPosture = CatPosture.sleeping;
        });
      }
    });
  }

  void _setPosture(CatPosture posture) {
    _sleepTimer?.cancel();
    if (posture == CatPosture.walking) {
      _startWalkingWithMessage();
    } else {
      _walkController.stop();
      setState(() {
        _currentPosture = posture;
      });
      if (posture == CatPosture.sitting) {
        _scheduleSleepTransition();
      }
    }
  }

  void _simulateNewMessage() {
    setState(() {
      _templateIndex = (_templateIndex + 1) % _sampleMessages.length;
      _currentMessage = _sampleMessages[_templateIndex];
    });

    _triggerHearts(_walkPosition.value + 150, 180);
    _startWalkingWithMessage();
  }

  @override
  Widget build(BuildContext context) {
    final double walkProgress = _walkController.value;
    final bool isWalking = _currentPosture == CatPosture.walking && _walkController.isAnimating;

    // Feline step vertical bobbing alami
    final double stepBob = isWalking ? sin(walkProgress * pi * 24).abs() * 5.0 : 0.0;
    final double stepTilt = isWalking ? sin(walkProgress * pi * 24) * 0.02 : 0.0;
    final double breatheScale = 1.0 + (_breatheController.value * 0.02);

    return Scaffold(
      backgroundColor: Colors.transparent, // Kanvas desktop transparan penuh!
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Bilah Kontrol Desktop (Anti-Kepotong / Auto-Fit)
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xE61E1E2C),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "🐾 Kucing LDM:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Simulasi Pesan Masuk
                      _actionButton(
                        icon: Icons.mark_email_unread_rounded,
                        label: "Chat Ayang",
                        color: const Color(0xFFFF5376),
                        onTap: _simulateNewMessage,
                      ),
                      const SizedBox(width: 10),
                      // Pemilih Postur Kucing Oren
                      _postureTab("🚶 Jalan", CatPosture.walking),
                      const SizedBox(width: 4),
                      _postureTab("🪑 Duduk", CatPosture.sitting),
                      const SizedBox(width: 4),
                      _postureTab("😴 Goler", CatPosture.sleeping),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Partikel Hati Melayang
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HeartPainter(_hearts),
              ),
            ),
          ),

          // 3. KUCING OREN 3D (KAKI MELANGKAH) + GROUND SHADOW + BALON CHAT
          Positioned(
            left: _walkPosition.value,
            bottom: 4 + stepBob,
            child: Transform.rotate(
              angle: stepTilt,
              child: SizedBox(
                width: 320,
                height: 330,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // A. Bayangan Tanah Realistis (Ambient Occlusion Ground Shadow)
                    Positioned(
                      bottom: 12,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPosture == CatPosture.sleeping
                            ? 190
                            : (_currentPosture == CatPosture.sitting ? 160 : 175),
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: _currentPosture == CatPosture.sleeping
                                      ? 0.55
                                      : 0.45),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // B. Kucing Oren 3D
                    Positioned(
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          _triggerHearts(_walkPosition.value + 160, 200);
                          if (_currentPosture == CatPosture.sleeping) {
                            setState(() {
                              _currentPosture = CatPosture.sitting;
                            });
                            _scheduleSleepTransition();
                            _showToast("Kucing oren bangun & menguap... Meooww! 🐱❤️");
                          } else {
                            _showToast("Purrrr... Kucing oren senang dielus! 🐾");
                          }
                        },
                        child: Transform.scale(
                          scale: _currentPosture == CatPosture.walking ? 1.0 : breatheScale,
                          child: SizedBox(
                            width: 260,
                            height: 210,
                            child: ModelViewer(
                              key: ValueKey(_currentPosture),
                              src: _getModelPath(_currentPosture),
                              autoPlay: true,
                              animationName: 'Animation',
                              cameraOrbit: _currentPosture == CatPosture.walking
                                  ? '75deg 75deg 105%'
                                  : '0deg 75deg 105%',
                              interactionPrompt: InteractionPrompt.none,
                              cameraControls: true,
                              backgroundColor: Colors.transparent,
                              progressBarColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // C. Balon Chat Pasangan di Atas Kucing Oren
                    if (_showBalloon)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildSpeechBalloon(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFFF5376),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 300, right: 300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _postureTab(String label, CatPosture posture) {
    final bool isSelected = _currentPosture == posture;
    return InkWell(
      onTap: () => _setPosture(posture),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Balon Obrolan Kustom yang Menempel di atas Kucing
  Widget _buildSpeechBalloon() {
    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: _showBalloon ? 1.0 : 0.0,
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFF8FA3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE5EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 12, color: Color(0xFFFF5376)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    Text(
                      "${_messageTime.hour.toString().padLeft(2, '0')}:${_messageTime.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _showBalloon = false),
                      child: const Icon(Icons.close_rounded,
                          size: 15, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _currentMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B2B2B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _quickReplyPill("Love you too ❤️"),
                    const SizedBox(width: 5),
                    _quickReplyPill("Iya ayang 🥰"),
                    const SizedBox(width: 5),
                    _quickReplyPill("Kangen 💕"),
                  ],
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(18, 10),
            painter: BalloonTailPainter(),
          ),
        ],
      ),
    );
  }

  Widget _quickReplyPill(String text) {
    return InkWell(
      onTap: () {
        _triggerHearts(_walkPosition.value + 160, 180);
        _showToast("Terkirim ke ayang: \"$text\" 💕");
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD1DC)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFFF5376),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class BalloonTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFF8FA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawLine(
        const Offset(0, 0), Offset(size.width / 2, size.height), borderPaint);
    canvas.drawLine(Offset(size.width / 2, size.height),
        Offset(size.width, 0), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FloatingHeart {
  final double startX;
  final double startY;
  final double size;
  final Color color;
  double progress = 0.0;

  FloatingHeart({
    required this.startX,
    required this.startY,
    required this.size,
    required this.color,
  });
}

class HeartPainter extends CustomPainter {
  final List<FloatingHeart> hearts;

  HeartPainter(this.hearts);

  @override
  void paint(Canvas canvas, Size size) {
    for (var heart in hearts) {
      final y = heart.startY - (heart.progress * 110);
      final x = heart.startX + sin(heart.progress * pi * 3.5) * 14;
      final opacity = (1.0 - heart.progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = heart.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      _drawHeart(
          canvas, Offset(x, y), heart.size * (0.8 + 0.4 * heart.progress), paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final width = size;
    final height = size;
    final x = center.dx - width / 2;
    final y = center.dy - height / 2;

    path.moveTo(x + width / 2, y + height / 4);
    path.cubicTo(x + width / 2, y, x, y, x, y + height / 3);
    path.cubicTo(
        x, y + height * 0.6, x + width / 2, y + height * 0.8, x + width / 2, y + height);
    path.cubicTo(x + width / 2, y + height * 0.8, x + width, y + height * 0.6,
        x + width, y + height / 3);
    path.cubicTo(x + width, y, x + width / 2, y, x + width / 2, y + height / 4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
