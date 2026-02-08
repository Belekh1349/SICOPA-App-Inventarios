
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class CsvImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> importBienesFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Needed for web, but good generally if small file
      );

      if (result != null) {
        String csvString;
        if (kIsWeb) {
          // Web handling
          final bytes = result.files.first.bytes;
          if (bytes == null) return;
          csvString = utf8.decode(bytes);
        } else {
          // Mobile/Desktop handling
          final path = result.files.single.path;
          if (path == null) return;
          final file = File(path);
          csvString = await file.readAsString();
        }

        List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

        if (csvData.isEmpty) return;

        // Verify headers (optional but recommended)
        List<dynamic> headers = csvData[0];
        // Expected: SECRETARÍA, UNIDAD ADMINISTRATIVA, ÁREA, ...
        // We can just assume order if strict, or map by index.

        // Skip header row
        for (var i = 1; i < csvData.length; i++) {
          List<dynamic> row = csvData[i];
          if (row.length < 18) continue; // Skip incomplete rows

          try {
            await _processRow(row);
          } catch (e) {
            print('Error processing row $i: $e');
            // Continue with next row
          }
        }
      }
    } catch (e) {
      print('Error importing CSV: $e');
      throw e;
    }
  }

  Future<void> _processRow(List<dynamic> row) async {
    // Map columns by index based on user provided list
    // 0: SECRETARÍA
    // 1: UNIDAD ADMINISTRATIVA
    // 2: ÁREA
    // 3: SERVIDOR PÚBLICO
    // 4: NIC
    // 5: INVENTARIO
    // 6: BIEN MUEBLE
    // 7: ESTADO DE USO
    // 8: FECHA ADQ
    // 9: VALOR
    // 10: SALARIO UMAS
    // 11: CARACTERISTICAS
    // 12: MATERIAL
    // 13: COLOR
    // 14: MARCA
    // 15: MODELO
    // 16: SERIE
    // 17: ACTIVO GENÉRICO

    String secretaria = row[0].toString();
    String unidadAdministrativa = row[1].toString();
    String area = row[2].toString();
    String servidorPublico = row[3].toString();
    String nic = row[4].toString();
    String inventario = row[5].toString();
    String descripcion = row[6].toString();
    String estadoUso = row[7].toString();
    
    // Parse Date
    DateTime? fechaAdquisicion;
    try {
      // Try parsing if string, format dependent
        // Assuming maybe ISO or simple formats
      if (row[8] != null && row[8].toString().isNotEmpty) {
          fechaAdquisicion = DateTime.tryParse(row[8].toString()); 
          // If fail, maybe implement custom parser later
      }
    } catch (_) {}

    // Parse numeric
    double valor = 0.0;
    try {
       String valStr = row[9].toString().replaceAll(RegExp(r'[^\d.]'), '');
       valor = double.tryParse(valStr) ?? 0.0;
    } catch (_) {}

    double salarioUmas = 0.0;
    try {
       String valStr = row[10].toString().replaceAll(RegExp(r'[^\d.]'), '');
       salarioUmas = double.tryParse(valStr) ?? 0.0;
    } catch (_) {}

    String caracteristicas = row[11].toString();
    String material = row[12].toString();
    String color = row[13].toString();
    String marca = row[14].toString();
    String modelo = row[15].toString();
    String serie = row[16].toString();
    String activoGenerico = row[17].toString();

    // Mapping to Firestore 'bienes' collection
    // ID could be auto-generated or based on 'inventario' if unique
    
    // Check if exists? For create/update logic. 
    // For now, let's assume insert. Using 'inventario' as ID if available and unique might be good, 
    // but 'nic' is also a candidate.
    // Let's use Firestore auto-id for safety unless specified.

    await _firestore.collection('bienes').add({
      'secretaria': secretaria,
      'unidadAdministrativa': unidadAdministrativa,
      'area': area,
      'servidorPublico': servidorPublico,
      'nic': nic,
      'inventario': inventario,
      'descripcion': descripcion,
      'estadoUso': estadoUso,
      'fechaAdquisicion': fechaAdquisicion != null ? Timestamp.fromDate(fechaAdquisicion) : null,
      'valor': valor,
      'salarioUmas': salarioUmas,
      'caracteristicas': caracteristicas,
      'material': material,
      'color': color,
      'marca': marca,
      'modelo': modelo,
      'serie': serie,
      'activoGenerico': activoGenerico,
      'status': 'POR_UBICAR',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
