
import 'package:cloud_firestore/cloud_firestore.dart';

class Bien {
  final String? id; // Firestore Doc ID
  final String secretaria;
  final String unidadAdministrativa;
  final String area;
  final String servidorPublico;
  final String nic;
  final String inventario; // Codigo de barras?
  final String descripcion; // BIEN MUEBLE
  final String estadoUso;
  final DateTime? fechaAdquisicion;
  final double valor;
  final double salarioUmas;
  final String caracteristicas;
  final String material;
  final String color;
  final String marca;
  final String modelo;
  final String serie;
  final String activoGenerico;
  
  // Internal fields
  final String status; // UBICADO, POR_UBICAR, etc.
  final DateTime? ultimaVerificacion;
  final String? usuarioVerifico;

  Bien({
    this.id,
    required this.secretaria,
    required this.unidadAdministrativa,
    required this.area,
    required this.servidorPublico,
    required this.nic,
    required this.inventario,
    required this.descripcion,
    required this.estadoUso,
    this.fechaAdquisicion,
    required this.valor,
    required this.salarioUmas,
    required this.caracteristicas,
    required this.material,
    required this.color,
    required this.marca,
    required this.modelo,
    required this.serie,
    required this.activoGenerico,
    this.status = 'POR_UBICAR',
    this.ultimaVerificacion,
    this.usuarioVerifico,
  });

  Map<String, dynamic> toMap() {
    return {
      'secretaria': secretaria,
      'unidadAdministrativa': unidadAdministrativa,
      'area': area,
      'servidorPublico': servidorPublico,
      'nic': nic,
      'inventario': inventario,
      'descripcion': descripcion,
      'estadoUso': estadoUso,
      'fechaAdquisicion': fechaAdquisicion,
      'valor': valor,
      'salarioUmas': salarioUmas,
      'caracteristicas': caracteristicas,
      'material': material,
      'color': color,
      'marca': marca,
      'modelo': modelo,
      'serie': serie,
      'activoGenerico': activoGenerico,
      'status': status,
      'ultimaVerificacion': ultimaVerificacion,
      'usuarioVerifico': usuarioVerifico,
    };
  }

  factory Bien.fromMap(Map<String, dynamic> map, String id) {
    return Bien(
      id: id,
      secretaria: map['secretaria'] ?? '',
      unidadAdministrativa: map['unidadAdministrativa'] ?? '',
      area: map['area'] ?? '',
      servidorPublico: map['servidorPublico'] ?? '',
      nic: map['nic'] ?? '',
      inventario: map['inventario'] ?? '',
      descripcion: map['descripcion'] ?? '',
      estadoUso: map['estadoUso'] ?? '',
      fechaAdquisicion: map['fechaAdquisicion'] != null 
          ? (map['fechaAdquisicion'] as Timestamp).toDate() 
          : null,
      valor: (map['valor'] ?? 0).toDouble(),
      salarioUmas: (map['salarioUmas'] ?? 0).toDouble(),
      caracteristicas: map['caracteristicas'] ?? '',
      material: map['material'] ?? '',
      color: map['color'] ?? '',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      serie: map['serie'] ?? '',
      activoGenerico: map['activoGenerico'] ?? '',
      status: map['status'] ?? 'POR_UBICAR',
      ultimaVerificacion: map['ultimaVerificacion'] != null 
          ? (map['ultimaVerificacion'] as Timestamp).toDate() 
          : null,
      usuarioVerifico: map['usuarioVerifico'],
    );
  }
}
