import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';
import 'dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
              child: Icon(Icons.account_balance, size: 60, color: Color(0xFFA62145)),
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
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo Curvo Asimétrico
          ClipPath(
            clipper: BackgroundClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA62145), Color(0xFF7D1632)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 40),
                Center(
                  child: Hero(
                    tag: 'logo',
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance, size: 50, color: Color(0xFFA62145)),
                          SizedBox(height: 8),
                          Text("GEM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFA62145))),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "SICOPA",
                  style: TextStyle(
                    fontSize: 36, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Sistema de Control Patrimonial",
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                
                Spacer(),
                
                // Características principales
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      _featureRow(Icons.qr_code_scanner, "Escaneo QR y NFC"),
                      SizedBox(height: 15),
                      _featureRow(Icons.inventory_2, "Control de Inventario"),
                      SizedBox(height: 15),
                      _featureRow(Icons.track_changes, "Seguimiento en tiempo real"),
                    ],
                  ),
                ),
                
                Spacer(),
                
                // Botones de acción
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFA62145),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 8,
                        ),
                        child: Text("INICIAR SESIÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                        },
                      ),
                      SizedBox(height: 15),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFFA62145),
                          minimumSize: Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          side: BorderSide(color: Color(0xFFA62145), width: 2),
                        ),
                        child: Text("MODO INVITADO (SOLO VER)", style: TextStyle(fontSize: 14)),
                        onPressed: () {
                          // Modo demo sin autenticación
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(isGuest: true)));
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                
                // Logo Gobierno del Estado de México
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Color(0xFFA62145),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Gobierno del Estado de", style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text("MÉXICO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        margin: EdgeInsets.symmetric(horizontal: 15),
                        color: Colors.white38,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Estado de", style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text("MÉXICO", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)),
                          Text("¡El poder de servir!", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFFA62145).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Color(0xFFA62145), size: 24),
        ),
        SizedBox(width: 15),
        Text(text, style: TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}

class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.85);
    
    var firstControlPoint = Offset(size.width * 0.25, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.85);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.7);
    var secondEndPoint = Offset(size.width, size.height * 0.9);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
