import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../services/csv_import_service.dart';


class RespaldoScreen extends StatefulWidget {
  @override
  _RespaldoScreenState createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends State<RespaldoScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  int _processedCount = 0;
  int _totalCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Carga Masiva"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 30),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Importar Bienes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 5),
                        Text(
                          "Carga un archivo CSV con los bienes patrimoniales para importarlos masivamente al sistema.",
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 25),
            
            // Formato esperado
            Text("Formato del archivo CSV (Estructura requerida)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Columnas requeridas en este orden:", style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  _buildColumnInfo("1", "SECRETARÍA"),
                  _buildColumnInfo("2", "UNIDAD ADMINISTRATIVA"),
                  _buildColumnInfo("3", "ÁREA"),
                  _buildColumnInfo("4", "SERVIDOR PÚBLICO"),
                  _buildColumnInfo("5", "NIC"),
                  _buildColumnInfo("6", "INVENTARIO"),
                  _buildColumnInfo("7", "BIEN MUEBLE (Descripción)"),
                  _buildColumnInfo("8", "ESTADO DE USO"),
                  _buildColumnInfo("9", "FECHA ADQ"),
                  _buildColumnInfo("10", "VALOR"),
                  _buildColumnInfo("11", "SALARIO UMAS"),
                  _buildColumnInfo("...", "Y el resto de características..."),
                ],
              ),
            ),
            
            SizedBox(height: 25),
            
            // Ejemplo CSV
            Text("Ejemplo de Cabecera", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  'SECRETARÍA,UNIDAD ADMINISTRATIVA,ÁREA,SERVIDOR PÚBLICO,NIC,INVENTARIO,BIEN MUEBLE,ESTADO DE USO,...\n'
                  'SECRETARIA DE FINANZAS,DIRECCIÓN GENERAL,DEPARTAMENTO A,JUAN PEREZ,NIC001,INV123,ESCRITORIO,BUENO,...',
                  style: TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Status de carga
            if (_statusMessage != null)
              Container(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isLoading ? Colors.blue : Colors.green),
                ),
                child: Column(
                  children: [
                    if (_isLoading)
                      CircularProgressIndicator(color: Color(0xFFA62145)),
                    SizedBox(height: 10),
                    Text(_statusMessage!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            
            // Botón de carga
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA62145),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                ),
                icon: Icon(Icons.upload_file),
                label: Text("SELECCIONAR Y CARGAR CSV", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _isLoading ? null : _importarConServicio,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Descargar plantilla
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.download),
                label: Text("Ver estructura completa"),
                onPressed: () {
                   showDialog(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: Text("Columnas en orden"),
                       content: SingleChildScrollView(
                         child: Text("1. SECRETARÍA\n2. UNIDAD ADMINISTRATIVA\n3. ÁREA\n4. SERVIDOR PÚBLICO\n5. NIC\n6. INVENTARIO\n7. BIEN MUEBLE\n8. ESTADO DE USO\n9. FECHA ADQ\n10. VALOR\n11. SALARIO UMAS\n12. CARACTERISTICAS\n13. MATERIAL\n14. COLOR\n15. MARCA\n16. MODELO\n17. SERIE\n18. ACTIVO GENÉRICO"),
                       ),
                       actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Cerrar"))],
                     ),
                   );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColumnInfo(String column, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFFA62145).withOpacity(0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(column, style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(description, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
  
  Future<void> _selectAndProcessFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      
      if (result == null || result.files.isEmpty) {
        return;
      }
      
      final file = result.files.first;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo leer el archivo"), backgroundColor: Colors.red),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
        _statusMessage = "Procesando archivo...";
        _processedCount = 0;
        _totalCount = 0;
      });
      
      // Decodificar CSV
      final csvString = utf8.decode(file.bytes!);
      final rows = const CsvToListConverter().convert(csvString);
      
      if (rows.isEmpty || rows.length < 2) {
        setState(() {
          _isLoading = false;
          _statusMessage = "El archivo está vacío o no tiene datos válidos";
        });
        return;
      }
      
      // Primera fila es el header
      final headers = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
      final dataRows = rows.sublist(1);
      
      // Validar columnas requeridas
      if (!headers.contains('codigo') || !headers.contains('descripcion')) {
        setState(() {
          _isLoading = false;
          _statusMessage = "El archivo debe tener las columnas 'codigo' y 'descripcion'";
        });
        return;
      }
      
      final codigoIndex = headers.indexOf('codigo');
      final descripcionIndex = headers.indexOf('descripcion');
      final ubicacionIndex = headers.contains('ubicacion') ? headers.indexOf('ubicacion') : -1;
      final resguardatarioIndex = headers.contains('resguardatario') ? headers.indexOf('resguardatario') : -1;
      final areaIndex = headers.contains('area') ? headers.indexOf('area') : -1;
      final valorIndex = headers.contains('valor') ? headers.indexOf('valor') : -1;
      
      setState(() {
        _totalCount = dataRows.length;
        _statusMessage = "Importando ${dataRows.length} bienes...";
      });
      
      // Procesar en batches
      final batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;
      int successCount = 0;
      
      for (var row in dataRows) {
        if (row.length > descripcionIndex) {
          final codigo = row[codigoIndex]?.toString() ?? '';
          final descripcion = row[descripcionIndex]?.toString() ?? '';
          
          if (descripcion.isNotEmpty) {
            final docRef = FirebaseFirestore.instance.collection('bienes').doc();
            
            batch.set(docRef, {
              'codigo': codigo,
              'descripcion': descripcion,
              'ubicacion': ubicacionIndex >= 0 && row.length > ubicacionIndex ? row[ubicacionIndex]?.toString() ?? '' : '',
              'resguardatario': resguardatarioIndex >= 0 && row.length > resguardatarioIndex ? row[resguardatarioIndex]?.toString() ?? '' : '',
              'area': areaIndex >= 0 && row.length > areaIndex ? row[areaIndex]?.toString() ?? '' : '',
              'valor': valorIndex >= 0 && row.length > valorIndex ? double.tryParse(row[valorIndex]?.toString() ?? '') : null,
              'status': 'POR_UBICAR',
              'fechaRegistro': FieldValue.serverTimestamp(),
            });
            
            batchCount++;
            successCount++;
            
            // Commit cada 400 documentos (límite de Firestore es 500)
            if (batchCount >= 400) {
              await batch.commit();
              batchCount = 0;
            }
          }
        }
        
        setState(() => _processedCount++);
      }
      
      // Commit final
      if (batchCount > 0) {
        await batch.commit();
      }
      
      setState(() {
        _isLoading = false;
        _statusMessage = "✅ Importación completada: $successCount bienes agregados";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Se importaron $successCount bienes exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "❌ Error: $e";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al procesar archivo: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importarConServicio() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Cargando bienes...";
    });

    try {
      final service = CsvImportService();
      await service.importBienesFromCsv();
      
      setState(() {
        _isLoading = false;
        _statusMessage = "✅ Importación completada con éxito";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "❌ Error en la importación";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
