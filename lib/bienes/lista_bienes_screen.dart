import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../widgets/bien_detail_sheet.dart';

class ListaBienesScreen extends StatefulWidget {
  final String? filterAreaId;
  final String? filterAreaNombre;
  final String? filterSecretariaNombre;
  final String? filterUnidadNombre;
  final String? filterServidorNombre;

  ListaBienesScreen({
    this.filterAreaId, 
    this.filterAreaNombre,
    this.filterSecretariaNombre,
    this.filterUnidadNombre,
    this.filterServidorNombre,
  });

  @override
  _ListaBienesScreenState createState() => _ListaBienesScreenState();
}

class _ListaBienesScreenState extends State<ListaBienesScreen> {
  String _searchQuery = '';
  String _filterStatus = 'TODOS';
  final _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    String title = "Lista de Bienes";
    String bannerText = "";

    if (widget.filterServidorNombre != null) {
      title = "Bienes de: ${widget.filterServidorNombre}";
      bannerText = "Servidor: ${widget.filterServidorNombre}";
    } else if (widget.filterAreaNombre != null) {
      title = "Área: ${widget.filterAreaNombre}";
      bannerText = "Área: ${widget.filterAreaNombre}";
    } else if (widget.filterUnidadNombre != null) {
      title = "Unidad: ${widget.filterUnidadNombre}";
      bannerText = "Unidad: ${widget.filterUnidadNombre}";
    } else if (widget.filterSecretariaNombre != null) {
      title = "Secretaría: ${widget.filterSecretariaNombre}";
      bannerText = "Secretaría: ${widget.filterSecretariaNombre}";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontSize: 16)),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'TODOS', child: Text('Todos')),
              PopupMenuItem(value: 'UBICADO', child: Text('Ubicados')),
              PopupMenuItem(value: 'MOVIMIENTO', child: Text('En Movimiento')),
              PopupMenuItem(value: 'NO_UBICADO', child: Text('No Ubicados')),
              PopupMenuItem(value: 'POR_UBICAR', child: Text('Por Ubicar')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.filterAreaNombre != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Mostrando bienes de: ${widget.filterAreaNombre}",
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFFA62145).withOpacity(0.1),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por descripción, código o ubicación...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          if (_filterStatus != 'TODOS')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(_getStatusLabel(_filterStatus)),
                    backgroundColor: _getStatusColor(_filterStatus).withOpacity(0.2),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _filterStatus = 'TODOS'),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                        Text("Error al cargar datos", style: TextStyle(fontSize: 16)),
                        Text("${snapshot.error}", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                final filteredDocs = docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final descripcion = (data['descripcion'] ?? '').toString().toLowerCase();
                  final codigo = (data['codigo'] ?? '').toString().toLowerCase();
                  final ubicacion = (data['ubicacion'] ?? '').toString().toLowerCase();
                  return descripcion.contains(_searchQuery) || 
                         codigo.contains(_searchQuery) ||
                         ubicacion.contains(_searchQuery);
                }).toList();
                
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 80, color: Colors.grey.shade300),
                        SizedBox(height: 15),
                        Text(
                          _searchQuery.isNotEmpty ? "Sin resultados para '$_searchQuery'" : "No hay bienes registrados",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: [
                    if (bannerText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Color(0xFFA62145).withOpacity(0.1),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt, size: 16, color: Color(0xFFA62145)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Filtrado por: $bannerText",
                                style: TextStyle(color: Color(0xFFA62145), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 16, color: Color(0xFFA62145)),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          data['id_doc'] = doc.id; // Importante para BienDetailSheet
                          return _buildBienCard(data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBienDialog(),
        backgroundColor: Color(0xFFA62145),
        icon: Icon(Icons.add),
        label: Text("Nuevo Bien"),
      ),
    );
  }
  
  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('bienes');
    
    if (widget.filterServidorNombre != null) {
      query = query.where('servidorPublico', isEqualTo: widget.filterServidorNombre!.toUpperCase());
    } else if (widget.filterAreaId != null) {
      query = query.where('areaId', isEqualTo: widget.filterAreaId);
    } else if (widget.filterAreaNombre != null) {
      query = query.where('area', isEqualTo: widget.filterAreaNombre!.toUpperCase());
    } else if (widget.filterUnidadNombre != null) {
      query = query.where('unidadAdministrativa', isEqualTo: widget.filterUnidadNombre!.toUpperCase());
    } else if (widget.filterSecretariaNombre != null) {
      query = query.where('secretaria', isEqualTo: widget.filterSecretariaNombre!.toUpperCase());
    }
    
    if (_filterStatus != 'TODOS') {
      query = query.where('status', isEqualTo: _filterStatus);
    }
    
    return query.snapshots();
  }
  
  Widget _buildBienCard(Map<String, dynamic> bien) {
    final status = bien['status'] ?? 'POR_UBICAR';
    final resguardatario = bien['servidorPublico'] ?? bien['resguardatario'] ?? 'Sin asignar';
    final secretaria = bien['secretaria'] ?? '';
    final unidad = bien['unidadAdministrativa'] ?? '';
    final area = bien['area'] ?? '';
    final inventario = bien['inventario'] ?? bien['id_doc'] ?? 'N/A';
    
    String hierarchy = "";
    if (secretaria.isNotEmpty) hierarchy += secretaria;
    if (unidad.isNotEmpty) hierarchy += (hierarchy.isEmpty ? "" : " > ") + unidad;
    if (area.isNotEmpty) hierarchy += (hierarchy.isEmpty ? "" : " > ") + area;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => BienDetailSheet(
              bien: bien,
              onStatusChanged: (newStatus) {
                // El StreamBuilder lo actualizará auto
              },
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  image: bien['imageUrl'] != null
                      ? (bien['imageUrl'].toString().startsWith('data:image')
                          ? DecorationImage(
                              image: MemoryImage(
                                base64Decode(bien['imageUrl'].split(',').last),
                              ),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: NetworkImage(bien['imageUrl']),
                              fit: BoxFit.cover,
                            ))
                      : null,
                ),
                child: bien['imageUrl'] == null
                    ? Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 28)
                    : null,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bien['descripcion'] ?? 'Sin descripción',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hierarchy.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        hierarchy,
                        style: TextStyle(color: Color(0xFFA62145), fontSize: 11, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            resguardatario,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.tag, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          "Inv: $inventario",
                          style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusShortLabel(status),
        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  void _showAddBienDialog() {
    final descController = TextEditingController();
    final inventarioController = TextEditingController();
    final nicController = TextEditingController();
    final secretariaController = TextEditingController(text: widget.filterSecretariaNombre);
    final unidadController = TextEditingController(text: widget.filterUnidadNombre);
    final areaController = TextEditingController(text: widget.filterAreaNombre);
    final ubicacionController = TextEditingController();
    final resguardatarioController = TextEditingController(text: widget.filterServidorNombre);
    final marcaController = TextEditingController();
    final modeloController = TextEditingController();
    final serieController = TextEditingController();
    final estadoUsoController = TextEditingController(text: "BUENO");
    final colorController = TextEditingController();
    final materialController = TextEditingController();
    final valorController = TextEditingController();
    final obsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_business, color: Color(0xFFA62145)),
            SizedBox(width: 10),
            Text("Nuevo Registro de Bien"),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormSection("DATOS PRINCIPALES"),
                _buildFormField(descController, "Descripción del Bien *", Icons.description),
                _buildFormField(inventarioController, "No. Inventario", Icons.inventory),
                _buildFormField(nicController, "NIC / Código de Barras", Icons.qr_code),
                
                SizedBox(height: 15),
                _buildFormSection("ESTRUCTURA Y UBICACIÓN"),
                _buildFormField(secretariaController, "Secretaría", Icons.account_balance),
                _buildFormField(unidadController, "Unidad Administrativa", Icons.business),
                _buildFormField(areaController, "Área", Icons.location_on),
                _buildFormField(ubicacionController, "Ubicación Física", Icons.place),
                _buildFormField(resguardatarioController, "Servidor Público (Resguardatario)", Icons.person),
                
                SizedBox(height: 15),
                _buildFormSection("DETALLES TÉCNICOS"),
                Row(
                  children: [
                    Expanded(child: _buildFormField(marcaController, "Marca", Icons.branding_watermark)),
                    SizedBox(width: 10),
                    Expanded(child: _buildFormField(modeloController, "Modelo", Icons.style)),
                  ],
                ),
                _buildFormField(serieController, "Número de Serie", Icons.format_list_numbered),
                Row(
                  children: [
                    Expanded(child: _buildFormField(colorController, "Color", Icons.color_lens)),
                    SizedBox(width: 10),
                    Expanded(child: _buildFormField(materialController, "Material", Icons.layers)),
                  ],
                ),
                _buildFormField(estadoUsoController, "Estado de Uso", Icons.info_outline),
                
                SizedBox(height: 15),
                _buildFormSection("INFORMACIÓN ADICIONAL"),
                _buildFormField(valorController, "Valor Contable", Icons.attach_money, keyboardType: TextInputType.number),
                _buildFormField(obsController, "Observaciones", Icons.note, maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFA62145),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (descController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("La descripción es obligatoria"), backgroundColor: Colors.red),
                );
                return;
              }
              
              try {
                await FirebaseFirestore.instance.collection('bienes').add({
                  'descripcion': descController.text.toUpperCase(),
                  'inventario': inventarioController.text.toUpperCase(),
                  'nic': nicController.text.toUpperCase(),
                  'codigo': nicController.text.toUpperCase(),
                  'secretaria': secretariaController.text.toUpperCase(),
                  'unidadAdministrativa': unidadController.text.toUpperCase(),
                  'area': areaController.text.toUpperCase(),
                  'ubicacion': ubicacionController.text.toUpperCase(),
                  'servidorPublico': resguardatarioController.text.toUpperCase(),
                  'resguardatario': resguardatarioController.text.toUpperCase(),
                  'marca': marcaController.text.toUpperCase(),
                  'modelo': modeloController.text.toUpperCase(),
                  'serie': serieController.text.toUpperCase(),
                  'estadoUso': estadoUsoController.text.toUpperCase(),
                  'color': colorController.text.toUpperCase(),
                  'material': materialController.text.toUpperCase(),
                  'valor': valorController.text,
                  'observaciones': obsController.text,
                  'status': 'POR_UBICAR',
                  'fechaRegistro': FieldValue.serverTimestamp(),
                  'ultimaVerificacion': null,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Bien registrado exitosamente"), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: Text("Guardar Registro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA62145), letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildFormField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
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
      case 'UBICADO': return 'Ubicados';
      case 'MOVIMIENTO': return 'En Movimiento';
      case 'NO_UBICADO': return 'No Ubicados';
      case 'POR_UBICAR': return 'Por Ubicar';
      default: return status;
    }
  }
  
  String _getStatusShortLabel(String status) {
    switch (status) {
      case 'UBICADO': return 'Ubicado';
      case 'MOVIMIENTO': return 'Movim.';
      case 'NO_UBICADO': return 'No Ubic.';
      default: return 'Por Ubic.';
    }
  }
}
