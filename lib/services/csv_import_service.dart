
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class CsvImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> importBienesFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Use any to avoid extension filtering issues on some platforms
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return {'success': false, 'message': 'No se seleccionó ningún archivo'};
      }

      final file = result.files.first;
      if (file.extension != null && file.extension!.toLowerCase() != 'csv') {
        return {'success': false, 'message': 'El archivo debe ser de tipo CSV (actual: .${file.extension})'};
      }

      String csvString;
      try {
        if (kIsWeb) {
          final bytes = file.bytes;
          if (bytes == null) return {'success': false, 'message': 'No se pudieron leer los datos del archivo'};
          
          // Attempt UTF-8
          try {
            csvString = utf8.decode(bytes);
          } catch (e) {
            // Fallback to Latin-1
            csvString = latin1.decode(bytes);
          }
        } else {
          final path = file.path;
          if (path == null) return {'success': false, 'message': 'No se pudo obtener la ruta del archivo'};
          final ioFile = File(path);
          
          // Read as bytes first to handle encoding fallback
          final bytes = await ioFile.readAsBytes();
          try {
            csvString = utf8.decode(bytes);
          } catch (e) {
            csvString = latin1.decode(bytes);
          }
        }
      } catch (e) {
        return {'success': false, 'message': 'Error al decodificar el archivo: $e'};
      }

      // Detect delimiter (common ones)
      String delimiter = ',';
      if (csvString.contains(';')) {
        // Simple heuristic: if there are more semicolons than commas in the first few lines
        int commas = ','.allMatches(csvString.split('\n').first).length;
        int semicolons = ';'.allMatches(csvString.split('\n').first).length;
        if (semicolons > commas) delimiter = ';';
      }

      List<List<dynamic>> csvData = CsvToListConverter(fieldDelimiter: delimiter).convert(csvString);

      if (csvData.isEmpty) {
        return {'success': false, 'message': 'El archivo está vacío'};
      }

      int successCount = 0;
      int errorCount = 0;
      int skippedCount = 0;

      // Skip header row
      for (var i = 1; i < csvData.length; i++) {
        List<dynamic> row = csvData[i];
        
        // Check if row is mostly empty
        if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) {
          continue;
        }

        // The user provided structure has 18 columns.
        // We'll be a bit more flexible but warn if it's too short.
        if (row.length < 7) { // At least up to BIEN MUEBLE
          skippedCount++;
          continue;
        }

        try {
          await _processRow(row);
          successCount++;
        } catch (e) {
          print('Error processing row $i: $e');
          errorCount++;
        }
      }

      return {
        'success': successCount > 0,
        'message': successCount > 0 
            ? 'Importación completada: $successCount exitosos, $errorCount errores, $skippedCount ignorados.' 
            : 'No se pudo importar ningún registro. Revisa el formato.',
        'successCount': successCount,
        'errorCount': errorCount,
        'skippedCount': skippedCount,
      };
    } catch (e) {
      print('Error general en importación: $e');
      return {'success': false, 'message': 'Error crítico: $e'};
    }
  }

  Future<void> _processRow(List<dynamic> row) async {
    String getValue(int index) {
      if (index >= 0 && index < row.length) {
        return row[index]?.toString() ?? '';
      }
      return '';
    }

    // Normalizing names for matching but keeping local casing for display if possible?
    // User said "cambios en la ortografía", maybe the toUpperCase is too aggressive.
    // Let's use trim() and keep original case, but we need consistency for hierarchy.
    String secretaria = getValue(0).trim();
    String unidadAdministrativa = getValue(1).trim();
    String areaName = getValue(2).trim();
    String servidorPublico = getValue(3).trim();
    String nic = getValue(4).trim();
    String inventario = getValue(5).trim();
    String descripcion = getValue(6).trim();
    String estadoUso = getValue(7).trim();
    
    // Parse Date - Handle DD/MM/YYYY and YYYY-MM-DD
    DateTime? fechaAdquisicion;
    String fechaStr = getValue(8).trim();
    if (fechaStr.isNotEmpty) {
      fechaAdquisicion = DateTime.tryParse(fechaStr);
      if (fechaAdquisicion == null && fechaStr.contains('/')) {
        // Try DD/MM/YYYY
        try {
          List<String> parts = fechaStr.split('/');
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            if (year < 100) year += 2000; // Handle YY
            fechaAdquisicion = DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }

    // Parse numeric
    double valor = 0.0;
    String valorStr = getValue(9).replaceAll(RegExp(r'[^\d.]'), '');
    valor = double.tryParse(valorStr) ?? 0.0;

    double salarioUmas = 0.0;
    String umasStr = getValue(10).replaceAll(RegExp(r'[^\d.]'), '');
    salarioUmas = double.tryParse(umasStr) ?? 0.0;

    String caracteristicas = getValue(11);
    String material = getValue(12);
    String color = getValue(13);
    String marca = getValue(14);
    String modelo = getValue(15);
    String serie = getValue(16);
    String activoGenerico = getValue(17);

    // --- Dynamic Hierarchy Creation ---
    String? areaId;
    try {
      if (secretaria.isNotEmpty && unidadAdministrativa.isNotEmpty && areaName.isNotEmpty) {
        areaId = await _ensureHierarchyExists(secretaria, unidadAdministrativa, areaName);
      }
    } catch (e) {
      print("Warning: Could not create hierarchy: $e");
    }

    await _firestore.collection('bienes').add({
      'secretaria': secretaria,
      'unidadAdministrativa': unidadAdministrativa,
      'area': areaName,
      'areaId': areaId, // Link to the created structure
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

  Future<String?> _ensureHierarchyExists(String secName, String uniName, String areaName) async {
    // 1. Find or create Secretaria
    QuerySnapshot secQuery = await _firestore.collection('secretarias')
        .where('nombre', isEqualTo: secName).limit(1).get();
    
    String secId;
    if (secQuery.docs.isEmpty) {
      DocumentReference secRef = await _firestore.collection('secretarias').add({
        'nombre': secName,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      secId = secRef.id;
    } else {
      secId = secQuery.docs.first.id;
    }

    // 2. Find or create Unidad
    QuerySnapshot uniQuery = await _firestore.collection('secretarias').doc(secId).collection('unidades')
        .where('nombre', isEqualTo: uniName).limit(1).get();
    
    String uniId;
    if (uniQuery.docs.isEmpty) {
      DocumentReference uniRef = await _firestore.collection('secretarias').doc(secId).collection('unidades').add({
        'nombre': uniName,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      uniId = uniRef.id;
    } else {
      uniId = uniQuery.docs.first.id;
    }

    // 3. Find or create Area
    QuerySnapshot areaQuery = await _firestore.collection('secretarias').doc(secId).collection('unidades').doc(uniId).collection('areas')
        .where('nombre', isEqualTo: areaName).limit(1).get();
    
    if (areaQuery.docs.isEmpty) {
      DocumentReference areaRef = await _firestore.collection('secretarias').doc(secId).collection('unidades').doc(uniId).collection('areas').add({
        'nombre': areaName,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      return areaRef.id;
    } else {
      return areaQuery.docs.first.id;
    }
  }
}
