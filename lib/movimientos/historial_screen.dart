import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialScreen extends StatefulWidget {
  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String _filterType = 'TODOS';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de Movimientos"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterType = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'TODOS', child: Text('Todos')),
              PopupMenuItem(value: 'VERIFICACION', child: Text('Verificaciones')),
              PopupMenuItem(value: 'TRASLADO', child: Text('Traslados')),
              PopupMenuItem(value: 'BAJA', child: Text('Bajas')),
              PopupMenuItem(value: 'PRESTAMO', child: Text('Préstamos')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFA62145)));
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 15),
                  Text("Error al cargar historial"),
                ],
              ),
            );
          }
          
          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  SizedBox(height: 15),
                  Text("No hay movimientos registrados", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  if (_filterType != 'TODOS')
                    TextButton(
                      onPressed: () => setState(() => _filterType = 'TODOS'),
                      child: Text("Ver todos"),
                    ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildMovimientoCard(data);
            },
          );
        },
      ),
    );
  }
  
  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('movimientos')
        .orderBy('fecha', descending: true)
        .limit(100);
    
    if (_filterType != 'TODOS') {
      query = query.where('tipoMovimiento', isEqualTo: _filterType);
    }
    
    return query.snapshots();
  }
  
  Widget _buildMovimientoCard(Map<String, dynamic> mov) {
    final tipo = mov['tipoMovimiento'] ?? 'OTRO';
    final fecha = mov['fecha'] as Timestamp?;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showMovimientoDetails(mov),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getTipoColor(tipo).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getTipoIcon(tipo), color: _getTipoColor(tipo), size: 26),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getTipoColor(tipo),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getTipoLabel(tipo),
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _formatTimestamp(fecha),
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      mov['descripcionBien'] ?? 'Sin descripción',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mov['observaciones'] != null && mov['observaciones'].toString().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          mov['observaciones'],
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showMovimientoDetails(Map<String, dynamic> mov) {
    final tipo = mov['tipoMovimiento'] ?? 'OTRO';
    final fecha = mov['fecha'] as Timestamp?;
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTipoColor(tipo).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getTipoIcon(tipo), color: _getTipoColor(tipo), size: 30),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getTipoLabel(tipo), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(_formatTimestamp(fecha), style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),
            _detailRow("Bien", mov['descripcionBien'] ?? 'N/A'),
            _detailRow("ID Bien", mov['bienId'] ?? 'N/A'),
            if (mov['ubicacionOrigen'] != null)
              _detailRow("Origen", mov['ubicacionOrigen']),
            if (mov['ubicacionDestino'] != null)
              _detailRow("Destino", mov['ubicacionDestino']),
            if (mov['nuevoEstatus'] != null)
              _detailRow("Nuevo Estado", mov['nuevoEstatus']),
            _detailRow("Observaciones", mov['observaciones'] ?? 'Sin observaciones'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
  
  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'VERIFICACION': return Colors.green;
      case 'TRASLADO': return Colors.blue;
      case 'BAJA': return Colors.red;
      case 'PRESTAMO': return Colors.orange;
      default: return Colors.purple;
    }
  }
  
  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'VERIFICACION': return Icons.verified;
      case 'TRASLADO': return Icons.swap_horiz;
      case 'BAJA': return Icons.remove_circle;
      case 'PRESTAMO': return Icons.assignment_return;
      default: return Icons.history;
    }
  }
  
  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'VERIFICACION': return 'Verificación';
      case 'TRASLADO': return 'Traslado';
      case 'BAJA': return 'Baja';
      case 'PRESTAMO': return 'Préstamo';
      default: return tipo;
    }
  }
  
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
