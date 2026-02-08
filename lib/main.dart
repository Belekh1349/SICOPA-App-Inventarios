import 'package:flutter/material.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFA62145)),
        useMaterial3: true,
      ),
      home: PantallaInicio(),
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
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA62145), Color(0xFF7D1632)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              SizedBox(height: 100),
              Center(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Icon(Icons.account_balance, size: 80, color: Color(0xFFA62145)), // Placeholder para assets/logo_edomex.png
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                "VERIFICACIONES SICOPA",
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black87
                ),
              ),
              Spacer(),
              
              // Animación de Saludo
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  "Hola, Enrique David",
                  style: TextStyle(
                    fontSize: 18, 
                    color: Color(0xFFA62145),
                    fontWeight: FontWeight.w500
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA62145),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 8,
                  ),
                  child: Text("ENTRAR AL SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // Navegación al Dashboard
                  },
                ),
              ),
              SizedBox(height: 80),
            ],
          )
        ],
      ),
    );
  }
}

class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.85);
    
    // Curva Bezier asimétrica premium
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
