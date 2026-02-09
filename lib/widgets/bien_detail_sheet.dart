import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BienDetailSheet extends StatefulWidget {
  final Map<String, dynamic> bien;
  final Function(String)? onStatusChanged;
  final bool showVerifyOption;
  
  const BienDetailSheet({
    Key? key,
    required this.bien,
    this.onStatusChanged,
    this.showVerifyOption = true,
  }) : super(key: key);

  @override
  State<BienDetailSheet> createState() => _BienDetailSheetState();
}

class _BienDetailSheetState extends State<BienDetailSheet> {
  late String status;
  bool isUpdating = false;
  String? imageUrl;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    status = widget.bien['status'] ?? 'POR_UBICAR';
    imageUrl = widget.bien['imageUrl'];
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    ImageSource? source;

    if (kIsWeb) {
      // En Web/Safari Mobile, es mejor llamar directo para no perder el 'user gesture'
      // El navegador se encarga de dar la opción de Cámara o Galería.
      source = ImageSource.gallery; 
    } else {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Tomar Foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    }

    if (source == null) return;
    
    // Mover selección dentro de try-catch para capturar errores de permisos
    XFile? photo;
    try {
      photo = await picker.pickImage(
        source: source,
        maxWidth: 600, 
        imageQuality: 35, 
      );
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al abrir cámara/galería: $e"), backgroundColor: Colors.red),
      );
      return;
    }

    if (photo == null) return;

    setState(() => isUploadingImage = true);

    try {
      final String docId = widget.bien['id_doc'] ?? widget.bien['id'];
      
      // Leer bytes de la imagen
      final Uint8List imageBytes = await photo.readAsBytes();
      
      // Convertir a Base64
      final String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

      await FirebaseFirestore.instance
          .collection('bienes')
          .doc(docId)
          .update({'imageUrl': base64Image});

      setState(() {
        imageUrl = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Imagen guardada localmente en la DB"), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("Error saving base64 image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar imagen: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUploadingImage = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => isUpdating = true);
    try {
      final docId = widget.bien['id_doc'] ?? widget.bien['id'];
      if (docId != null) {
        await FirebaseFirestore.instance.collection('bienes').doc(docId).update({
          'status': newStatus,
          'ultimaVerificacion': FieldValue.serverTimestamp(),
          'fechaSincronizacion': FieldValue.serverTimestamp(),
        });
        
        setState(() => status = newStatus);
        widget.onStatusChanged?.call(newStatus);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Estado actualizado a $newStatus"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar: $e"), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header con imagen o icono
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: isUploadingImage ? null : _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          image: imageUrl != null && imageUrl!.startsWith('data:image')
                              ? DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(imageUrl!.split(',').last),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : (imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: imageUrl == null
                            ? Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 40)
                            : null,
                      ),
                      if (isUploadingImage)
                        CircularProgressIndicator(color: _getStatusColor(status)),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isUploadingImage ? null : _pickAndUploadImage,
                              customBorder: CircleBorder(),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFA62145),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bien['descripcion'] ?? 'Sin descripción',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(status),
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isUpdating) ...[
                            SizedBox(width: 10),
                            SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: _getStatusColor(status))),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  _buildSectionTitle("ESTRUCTURA ADMINISTRATIVA"),
                  _buildDetailItem(Icons.account_balance, "Secretaría", widget.bien['secretaria']),
                  _buildDetailItem(Icons.business, "Unidad", widget.bien['unidadAdministrativa']),
                  _buildDetailItem(Icons.location_on, "Área", widget.bien['area']),
                  _buildDetailItem(Icons.place, "Ubicación Física", widget.bien['ubicacion']),
                  
                  Divider(height: 30),
                  _buildSectionTitle("ASIGNACIÓN Y CONTROL"),
                  _buildDetailItem(Icons.person, "Resguardatario", widget.bien['servidorPublico'] ?? widget.bien['resguardatario']),
                  _buildDetailItem(Icons.inventory, "No. Inventario", widget.bien['inventario'] ?? widget.bien['id_doc']),
                  _buildDetailItem(Icons.qr_code, "NIC / Código", widget.bien['nic'] ?? widget.bien['codigo']),
                  
                  Divider(height: 30),
                  _buildSectionTitle("DETALLES TÉCNICOS"),
                  _buildDetailItem(Icons.info_outline, "Estado de Uso", widget.bien['estadoUso']),
                  _buildDetailItem(Icons.category, "Génerico", widget.bien['activoGenerico']),
                  _buildDetailItem(Icons.branding_watermark, "Marca", widget.bien['marca']),
                  _buildDetailItem(Icons.style, "Modelo", widget.bien['modelo']),
                  _buildDetailItem(Icons.format_list_numbered, "Serie", widget.bien['serie']),
                  
                  Divider(height: 30),
                  _buildSectionTitle("CARACTERÍSTICAS"),
                  _buildDetailItem(Icons.color_lens, "Color", widget.bien['color']),
                  _buildDetailItem(Icons.layers, "Material", widget.bien['material']),
                  _buildDetailItem(Icons.description, "Otras Características", widget.bien['caracteristicas']),
                  
                  Divider(height: 30),
                  _buildSectionTitle("INFORMACIÓN CONTABLE"),
                  _buildDetailItem(Icons.attach_money, "Valor", widget.bien['valor'] != null ? "\$${widget.bien['valor']}" : null),
                  _buildDetailItem(Icons.calendar_today, "Fecha Adquisición", _formatValue(widget.bien['fechaAdquisicion'])),
                  
                  if (widget.bien['observaciones'] != null || widget.bien['ultimaVerificacion'] != null) ...[
                    Divider(height: 30),
                    _buildSectionTitle("AUDITORÍA"),
                    if (widget.bien['ultimaVerificacion'] != null)
                      _buildDetailItem(Icons.history, "Última Verificación", _formatTimestamp(widget.bien['ultimaVerificacion'])),
                    if (widget.bien['observaciones'] != null)
                      _buildDetailItem(Icons.note, "Observaciones", widget.bien['observaciones']),
                  ],
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Botones de acción
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              children: [
                Text("Cambiar Estado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatusButton(context, "UBICADO", Colors.green, status)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatusButton(context, "MOVIMIENTO", Colors.blue, status)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatusButton(context, "POR_UBICAR", Colors.amber, status)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatusButton(context, "NO_UBICADO", Colors.red, status)),
                  ],
                ),
                if (widget.showVerifyOption) ...[
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.verified, color: Colors.white),
                      label: Text("VERIFICAR AHORA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFA62145),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isUpdating ? null : () => _updateStatus("UBICADO"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFFA62145),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty || value.toString() == "null") {
      return SizedBox.shrink();
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                SizedBox(height: 2),
                Text(
                  value.toString(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusButton(BuildContext context, String status, Color color, String currentStatus) {
    final isActive = status == currentStatus;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black54,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: isActive ? 4 : 0,
      ),
      onPressed: (isActive || isUpdating) ? null : () {
        _updateStatus(status);
      },
      child: Text(_getStatusShortLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'UBICADO': return Colors.green;
      case 'MOVIMIENTO': return Colors.blue;
      case 'NO_UBICADO': return Colors.red;
      default: return Colors.amber;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'UBICADO': return Icons.check_circle;
      case 'MOVIMIENTO': return Icons.sync;
      case 'NO_UBICADO': return Icons.error;
      default: return Icons.help_outline;
    }
  }
  
  String _getStatusLabel(String status) {
    switch (status) {
      case 'UBICADO': return 'UBICADO';
      case 'MOVIMIENTO': return 'EN MOVIMIENTO';
      case 'NO_UBICADO': return 'NO UBICADO';
      default: return 'POR UBICAR';
    }
  }
  
  String _getStatusShortLabel(String status) {
    switch (status) {
      case 'UBICADO': return 'Ubicado';
      case 'MOVIMIENTO': return 'Movimiento';
      case 'NO_UBICADO': return 'No Ubicado';
      default: return 'Por Ubicar';
    }
  }
  
  String? _formatValue(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) {
      final dt = date.toDate();
      return "${dt.day}/${dt.month}/${dt.year}";
    }
    return date.toString();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }
}
