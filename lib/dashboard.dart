import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Panel de Control - SICOPA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFA62145),
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
          IconButton(icon: Icon(Icons.account_circle, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatisticsHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildMenuCard(context, "Verificaciones", Icons.qr_code_scanner, Colors.blue),
                  _buildMenuCard(context, "Movimientos", Icons.swap_horiz, Colors.orange),
                  _buildMenuCard(context, "Historial", Icons.history, Colors.purple),
                  _buildMenuCard(context, "Reportes", Icons.file_present, Colors.red),
                  _buildMenuCard(context, "Carga Masiva", Icons.cloud_upload, Colors.teal),
                  _buildMenuCard(context, "Ajustes", Icons.settings, Colors.blueGrey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Color(0xFFA62145),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Estado Global del Inventario", style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("92%", "Ubicados", Icons.check_circle, Colors.greenAccent),
              _buildStatItem("05%", "Movimiento", Icons.sync, Colors.lightBlueAccent),
              _buildStatItem("03%", "Faltantes", Icons.error_outline, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 5),
        Text(val, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, String titulo, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Color(0xFFA62145)),
            SizedBox(height: 10),
            Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
