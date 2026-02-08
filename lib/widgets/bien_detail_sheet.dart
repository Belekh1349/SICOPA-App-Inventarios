import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    status = widget.bien['status'] ?? 'POR_UBICAR';
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
      height: MediaQuery.of(context).size.height * 0.7,
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
          
          // Header con estado
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getStatusIcon(status), color: Colors.white, size: 28),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bien['descripcion'] ?? 'Sin descripción',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
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
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
          
          // Detalles del bien
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow("Inventario (CSV)", widget.bien['inventario'] ?? 'N/A', Icons.inventory),
                  _buildDetailRow("ID Patrimonial", widget.bien['id'] ?? 'N/A', Icons.tag),
                  _buildDetailRow("Código de Barras", widget.bien['codigo'] ?? 'N/A', Icons.qr_code),
                  _buildDetailRow("Ubicación", widget.bien['ubicacion'] ?? 'Sin ubicación', Icons.location_on),
                  _buildDetailRow("Resguardatario", widget.bien['servidorPublico'] ?? widget.bien['resguardatario'] ?? 'Sin asignar', Icons.person),
                  _buildDetailRow("Área", widget.bien['area'] ?? 'N/A', Icons.business),
                  _buildDetailRow("Valor", widget.bien['valor'] != null ? '\$${widget.bien['valor']}' : 'N/A', Icons.attach_money),
                  if (widget.bien['observaciones'] != null && widget.bien['observaciones'].toString().isNotEmpty)
                    _buildDetailRow("Observaciones", widget.bien['observaciones'], Icons.notes),
                  if (widget.bien['ultimaVerificacion'] != null)
                    _buildDetailRow(
                      "Última Verificación", 
                      _formatTimestamp(widget.bien['ultimaVerificacion']), 
                      Icons.access_time
                    ),
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
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFA62145).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFFA62145), size: 20),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }
}
