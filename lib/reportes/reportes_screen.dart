import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportesScreen extends StatefulWidget {
  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool _isLoading = true;
  Map<String, int> _estadisticas = {};
  Map<String, int> _porUbicacion = {};
  Map<String, int> _porArea = {};
  
  @override
  void initState() {
    super.initState();
    _loadEstadisticas();
  }
  
  Future<void> _loadEstadisticas() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance.collection('bienes').get();
      
      Map<String, int> stats = {
        'total': 0,
        'UBICADO': 0,
        'MOVIMIENTO': 0,
        'NO_UBICADO': 0,
        'POR_UBICAR': 0,
        'BAJA': 0,
      };
      
      Map<String, int> ubicaciones = {};
      Map<String, int> areas = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        stats['total'] = stats['total']! + 1;
        
        final status = data['status'] ?? 'POR_UBICAR';
        stats[status] = (stats[status] ?? 0) + 1;
        
        final ubicacion = data['ubicacion'] ?? 'Sin ubicación';
        ubicaciones[ubicacion] = (ubicaciones[ubicacion] ?? 0) + 1;
        
        final area = data['area'] ?? 'Sin área';
        areas[area] = (areas[area] ?? 0) + 1;
      }
      
      if (mounted) {
        setState(() {
          _estadisticas = stats;
          _porUbicacion = ubicaciones;
          _porArea = areas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar estadísticas: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reportes"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEstadisticas,
          ),
        ],
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: Color(0xFFA62145)))
        : RefreshIndicator(
            onRefresh: _loadEstadisticas,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumen general
                  _buildSectionTitle("Resumen General"),
                  SizedBox(height: 15),
                  _buildResumenCard(),
                  
                  SizedBox(height: 30),
                  
                  // Estadísticas por estado
                  _buildSectionTitle("Estado de Bienes"),
                  SizedBox(height: 15),
                  _buildEstadosGrid(),
                  
                  SizedBox(height: 30),
                  
                  // Por ubicación
                  if (_porUbicacion.isNotEmpty) ...[
                    _buildSectionTitle("Por Ubicación"),
                    SizedBox(height: 15),
                    _buildListaUbicaciones(),
                  ],
                  
                  SizedBox(height: 30),
                  
                  // Acciones de reporte
                  _buildSectionTitle("Generar Reportes"),
                  SizedBox(height: 15),
                  _buildReporteButtons(),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
  
  Widget _buildResumenCard() {
    final total = _estadisticas['total'] ?? 0;
    final ubicados = _estadisticas['UBICADO'] ?? 0;
    final porcentaje = total > 0 ? (ubicados / total * 100) : 0;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA62145), Color(0xFF7D1632)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total de Bienes", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 5),
                  Text("$total", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.inventory, color: Colors.white, size: 40),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Barra de progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bienes Ubicados", style: TextStyle(color: Colors.white70)),
                  Text("${porcentaje.toStringAsFixed(1)}%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: porcentaje / 100,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEstadosGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildEstadoCard("Ubicados", _estadisticas['UBICADO'] ?? 0, Colors.green, Icons.check_circle),
        _buildEstadoCard("En Movimiento", _estadisticas['MOVIMIENTO'] ?? 0, Colors.blue, Icons.sync),
        _buildEstadoCard("No Ubicados", _estadisticas['NO_UBICADO'] ?? 0, Colors.red, Icons.error),
        _buildEstadoCard("Por Ubicar", _estadisticas['POR_UBICAR'] ?? 0, Colors.amber, Icons.help_outline),
      ],
    );
  }
  
  Widget _buildEstadoCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                "$count",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildListaUbicaciones() {
    final ubicacionesSorted = _porUbicacion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: ubicacionesSorted.length > 5 ? 5 : ubicacionesSorted.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = ubicacionesSorted[index];
          final porcentaje = _estadisticas['total']! > 0 
            ? (entry.value / _estadisticas['total']! * 100) 
            : 0;
          
          return ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFA62145).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.location_on, color: Color(0xFFA62145), size: 20),
            ),
            title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: LinearProgressIndicator(
              value: porcentaje / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA62145)),
            ),
            trailing: Text("${entry.value}", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
  
  Widget _buildReporteButtons() {
    return Column(
      children: [
        _buildReporteButton("Reporte General PDF", Icons.picture_as_pdf, Colors.red, () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Generando reporte PDF...")),
          );
          // Implementar generación de PDF
        }),
        SizedBox(height: 10),
        _buildReporteButton("Exportar a Excel", Icons.table_chart, Colors.green, () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Exportando a Excel...")),
          );
          // Implementar exportación a Excel
        }),
        SizedBox(height: 10),
        _buildReporteButton("Reporte por Área", Icons.business, Colors.blue, () {
          _showReportePorArea();
        }),
      ],
    );
  }
  
  Widget _buildReporteButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 15),
              Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showReportePorArea() {
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
            Text("Bienes por Área", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            if (_porArea.isEmpty)
              Center(child: Text("No hay datos de áreas", style: TextStyle(color: Colors.grey)))
            else
              ..._porArea.entries.map((entry) => ListTile(
                leading: Icon(Icons.business, color: Color(0xFFA62145)),
                title: Text(entry.key),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFA62145),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("${entry.value}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )).toList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
