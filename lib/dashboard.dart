import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Panel de Control - SICOPA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFA62145),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAFAFA), Color(0xFFE5E5E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildMenuCard(context, "Verificaciones", Icons.qr_code_scanner),
              _buildMenuCard(context, "Movimientos", Icons.swap_horiz),
              _buildMenuCard(context, "Historial", Icons.history),
              _buildMenuCard(context, "Reportes", Icons.file_present),
              _buildMenuCard(context, "Nuevo Registro", Icons.add_box),
              _buildMenuCard(context, "Configuración", Icons.settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String titulo, IconData icon) {
    return InkWell(
      onTap: () {
        // Lógica de navegación
      },
      splashColor: Color(0xFFA62145).withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFA62145).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 45, color: Color(0xFFA62145)),
              ),
              SizedBox(height: 15),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
