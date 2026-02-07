import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialMovimientosScreen extends StatelessWidget {
  final String bienId;
  final String nombreBien;

  HistorialMovimientosScreen({required this.bienId, required this.nombreBien});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de Bien"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildTimeline(), // Placeholder para stream de Firestore
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombreBien, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("ID de Inventario: $bienId", style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    // Simulando datos de movimientos
    final movimientos = [
      {'tipo': 'TRANSFERENCIA', 'fecha': '2024-02-01', 'destino': 'RRHH', 'origen': 'Sistemas'},
      {'tipo': 'REASIGNACION', 'fecha': '2023-11-15', 'destino': 'Sistemas', 'origen': 'Finanzas'},
      {'tipo': 'ENTRADA', 'fecha': '2023-01-10', 'destino': 'Finanzas', 'origen': 'Proveedor'},
    ];

    return ListView.builder(
      itemCount: movimientos.length,
      padding: EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final mov = movimientos[index];
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFFA62145),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index != movimientos.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Color(0xFFA62145).withOpacity(0.3),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mov['fecha']!, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA62145))),
                      SizedBox(height: 5),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mov['tipo']!, style: TextStyle(fontWeight: FontWeight.bold)),
                              Divider(),
                              Text("Origen: ${mov['origen']}"),
                              Text("Destino: ${mov['destino']}"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
