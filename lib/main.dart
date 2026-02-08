import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';
import 'dashboard.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SicopaApp());
}

class SicopaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SICOPA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFA62145),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFA62145),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFA62145),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

// Wrapper que decide si mostrar Login o Dashboard basado en autenticación
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras carga, mostrar splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        
        // Si hay usuario autenticado, ir al Dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return DashboardScreen();
        }
        
        // Si no hay usuario, mostrar pantalla de inicio con opción de login
        return PantallaInicio();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFA62145),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              // child: Icon(Icons.account_balance, size: 60, color: Color(0xFFA62145)),
              child: Image.asset('assets/images/logo_01.png', width: 80),
            ),
            SizedBox(height: 30),
            Text("SICOPA", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 3)),
            SizedBox(height: 10),
            Text("Sistema de Control Patrimonial", style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 50),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class PantallaInicio extends StatefulWidget {
  @override
  _PantallaInicioState createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );

    // Iniciar animación al cargar
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _navigateTo(Widget page) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve)); // Slide lateral suave
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: Duration(milliseconds: 800), // Lento y premium
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo Asimétrico (Color Institucional) - Reducido
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                color: Color(0xFFA62145), // Guinda Institucional
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(180),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(-5, 10))
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con Logo
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Opacity(
                      opacity: 0.95,
                      child: Image.asset('assets/images/logo_01.png', width: 180),
                    ),
                  ),
                ),

                Spacer(), // Espacio flexible superior

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título App con slide
                      SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 4,
                                width: 50,
                                color: Color(0xFFD4AF37), // Dorado Premium
                                margin: EdgeInsets.only(bottom: 15),
                              ),
                              Text(
                                "Verificaciones",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w300, 
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                "SICOPA",
                                style: TextStyle(
                                  fontSize: 48,
                                  color: Color(0xFFA62145),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  height: 1.0
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30),

                      // Saludo Personalizado Animado
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          padding: EdgeInsets.only(left: 15, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: Color(0xFFD4AF37), width: 3))
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Bienvenido al sistema,", style: TextStyle(color: Colors.grey[700], fontSize: 13, letterSpacing: 0.5)),
                              SizedBox(height: 5),
                              Text(
                                "Control Patrimonial",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Spacer(flex: 2), // Espacio central flexible

                // Botones de Acción
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      _buildPremiumButton(
                        text: "INICIAR SESIÓN",
                        isPrimary: true,
                        onTap: () => _navigateTo(LoginScreen()),
                      ),
                      SizedBox(height: 15),
                      _buildPremiumButton(
                        text: "MODO INVITADO",
                        isPrimary: false,
                        onTap: () {
                           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(isGuest: true)));
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 30),

                // Footer Logo integrado en la columna (sin overlaps)
                Center(
                  child: Opacity(
                     opacity: 0.8,
                     child: Image.asset(
                       'assets/images/logo.png', 
                       height: 50,
                       errorBuilder: (c, o, s) => Text("GOBIERNO DEL ESTADO DE MÉXICO", style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
                     ),
                  ),
                ),
                
                SizedBox(height: 20), // Padding final
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton({required String text, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: isPrimary ? Color(0xFFA62145) : Colors.transparent,
          borderRadius: BorderRadius.circular(30), // Bordes muy redondeados
          border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.grey.shade400,
            width: 1.5,
          ),
          boxShadow: isPrimary 
            ? [BoxShadow(color: Color(0xFFA62145).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))]
            : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
