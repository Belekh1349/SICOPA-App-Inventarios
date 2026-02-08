import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization skipped or failed: $e");
  }
  runApp(const SicopaApp());
}

class SicopaApp extends StatelessWidget {
  const SicopaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SICOPA',
      theme: ThemeData(
        primaryColor: const Color(0xFFA62145),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA62145),
          primary: const Color(0xFFA62145),
          secondary: const Color(0xFFD4AF37),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const PantallaInicio(),
    );
  }
}

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  _PantallaInicioState createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  String _displayText = "";
  final String _fullText = "Bienvenido al Sistema de Control Patrimonial\nSICOPA";
  int _charIndex = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _startTypewriter();

    // Navegación automática después de la animación (8 segundos para dar tiempo al efecto)
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_charIndex < _fullText.length) {
        if (mounted) {
          setState(() {
            _displayText += _fullText[_charIndex];
            _charIndex++;
          });
        }
      } else {
        _typewriterTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo decorativo con gradiente institutional
          ClipPath(
            clipper: BackgroundClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA62145), Color(0xFF7D1632)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo con sombra y glow
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA62145).withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(25),
                    child: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Emblema_del_Gobierno_del_Estado_de_M%C3%A9xico_per%C3%ADodo_2023-2029.png/800px-Emblema_del_Gobierno_del_Estado_de_M%C3%A9xico_per%C3%ADodo_2023-2029.png',
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator(color: Color(0xFFA62145));
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.account_balance,
                        size: 100,
                        color: Color(0xFFA62145),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Texto con efecto typewriter y tipografía moderna
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    height: 80, // Espacio fijo para evitar saltos
                    child: Text(
                      _displayText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA62145),
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Pie de página institucional
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                   Text(
                    "GOBIERNO DEL ESTADO DE MÉXICO",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "¡El poder de servir!",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFA62145),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.35);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.45, 
      size.width * 0.5, size.height * 0.35
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.25, 
      size.width, size.height * 0.35
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
