import 'package:flutter/material.dart';
// Requiere: file_picker, csv
// import 'package:file_picker/file_picker.dart';
// import 'package:csv/csv.dart';

class RespaldoScreen extends StatefulWidget {
  @override
  _RespaldoScreenState createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends State<RespaldoScreen> {
  bool _estaProcesando = false;
  double _progreso = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Administración de Datos"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Carga Masiva (CSV)", Icons.upload_file),
            SizedBox(height: 10),
            Text(
              "Sube un archivo .csv con la estructura oficial para actualizar el inventario global.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            _buildActionCard(
              "Seleccionar Archivo CSV",
              "Soporta miles de registros en pocos segundos.",
              Icons.file_present,
              Colors.blueAccent,
              _iniciarCargaMasiva,
            ),
            
            SizedBox(height: 40),
            _buildSectionHeader("Respaldo de Seguridad", Icons.security),
            SizedBox(height: 20),
            _buildActionCard(
              "Exportar Base Completa",
              "Descarga un respaldo local en formato JSON.",
              Icons.download,
              Color(0xFFA62145),
              _exportarRespaldo,
            ),

            if (_estaProcesando) ...[
              Spacer(),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(value: _progreso, color: Color(0xFFA62145)),
                    SizedBox(height: 10),
                    Text("Procesando información... ${(_progreso * 100).toInt()}%"),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFFA62145)),
        SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _estaProcesando ? null : onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 30),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
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

  void _iniciarCargaMasiva() async {
    // 1. Abrir selector de archivos: await FilePicker.platform.pickFiles(...)
    // 2. Parsear CSV: List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
    // 3. Convertir a JSON y llamar a Cloud Function: cargaMasivaBienes({'bienes': ...});
    
    setState(() { _estaProcesando = true; _progreso = 0.5; });
    
    // Simulación de carga
    await Future.delayed(Duration(seconds: 2));
    
    setState(() { _estaProcesando = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Carga completada con éxito"), backgroundColor: Colors.green),
    );
  }

  void _exportarRespaldo() {
    // Lógica para descargar todos los documentos de Firestore y guardarlos en local
  }
}
