import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          // Banner informativo si hay filtro por área
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

          // Barra de búsqueda
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
          
          // Chips de filtro activo
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
          
          // Lista de bienes
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
                
                // Filtrar por búsqueda
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
                
                return Column( // Wrap with Column to include the banner
                  children: [
                    // Banner informativo si hay filtros
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
                          data['id'] = doc.id;
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
    
    // Prioridad de filtros
    if (widget.filterServidorNombre != null) {
      // Intentamos filtrar por el nombre que viene (ya debería venir en Mayúsculas desde la navegación)
      // Nota: Firestore no soporta 'OR' fácilmente en consultas simples sin índices específicos,
      // pero usaremos 'servidorPublico' como principal. 
      // Si la navegación ya manda el campo correcto, esto funcionará.
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
    final inventario = bien['inventario'] ?? bien['id'] ?? 'N/A';
    
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
            builder: (context) => BienDetailSheet(bien: bien),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 24),
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
                        if (bien['nic'] != null) ...[
                          Text(" | ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(
                            "NIC: ${bien['nic']}",
                            style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ]
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
    final codigoController = TextEditingController();
    final ubicacionController = TextEditingController();
    final resguardatarioController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Registrar Nuevo Bien"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: "Descripción *", border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: codigoController,
                decoration: InputDecoration(labelText: "Código de Barras", border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: ubicacionController,
                decoration: InputDecoration(labelText: "Ubicación", border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: resguardatarioController,
                decoration: InputDecoration(labelText: "Resguardatario", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA62145)),
            onPressed: () async {
              if (descController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("La descripción es obligatoria"), backgroundColor: Colors.red),
                );
                return;
              }
              
              try {
                await FirebaseFirestore.instance.collection('bienes').add({
                  'descripcion': descController.text,
                  'codigo': codigoController.text,
                  'ubicacion': ubicacionController.text,
                  'resguardatario': resguardatarioController.text,
                  'status': 'POR_UBICAR',
                  'fechaRegistro': FieldValue.serverTimestamp(),
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
            child: Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
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

class BienDetailSheet extends StatelessWidget {
  final Map<String, dynamic> bien;
  
  const BienDetailSheet({Key? key, required this.bien}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  bien['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildStatusIndicator(bien['status'] ?? 'POR_UBICAR'),
            ],
          ),
          Divider(height: 30),
          Expanded(
            child: ListView(
              children: [
                _buildInfoSection("Estructura Administrativa", [
                  _infoRow(Icons.account_balance, "Secretaría", bien['secretaria']),
                  _infoRow(Icons.business, "Unidad", bien['unidadAdministrativa']),
                  _infoRow(Icons.location_on, "Área", bien['area']),
                ]),
                _buildInfoSection("Asignación", [
                  _infoRow(Icons.person, "Resguardatario", bien['servidorPublico']),
                  _infoRow(Icons.tag, "Inventario", bien['inventario']),
                  _infoRow(Icons.confirmation_number, "NIC", bien['nic']),
                ]),
                _buildInfoSection("Detalles del Bien", [
                  _infoRow(Icons.info_outline, "Estado", bien['estadoUso']),
                  _infoRow(Icons.category, "Génerico", bien['activoGenerico']),
                  _infoRow(Icons.branding_watermark, "Marca", bien['marca']),
                  _infoRow(Icons.style, "Modelo", bien['modelo']),
                  _infoRow(Icons.format_list_numbered, "Serie", bien['serie']),
                ]),
                _buildInfoSection("Características", [
                  _infoRow(Icons.color_lens, "Color", bien['color']),
                  _infoRow(Icons.layers, "Material", bien['material']),
                  _infoRow(Icons.text_fields, "Otros", bien['caracteristicas']),
                ]),
                _buildInfoSection("Contable", [
                  _infoRow(Icons.attach_money, "Valor", bien['valor']?.toString()),
                  _infoRow(Icons.calendar_today, "Adquisición", _formatDate(bien['fechaAdquisicion'])),
                ]),
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFA62145),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA62145))),
        ),
        ...children,
        SizedBox(height: 10),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Expanded(child: Text(value?.toString() ?? 'N/A', style: TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    switch (status) {
      case 'UBICADO': color = Colors.green; break;
      case 'MOVIMIENTO': color = Colors.blue; break;
      case 'NO_UBICADO': color = Colors.red; break;
      default: color = Colors.amber;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    if (date is Timestamp) {
      final dt = date.toDate();
      return "${dt.day}/${dt.month}/${dt.year}";
    }
    return date.toString();
  }
}
