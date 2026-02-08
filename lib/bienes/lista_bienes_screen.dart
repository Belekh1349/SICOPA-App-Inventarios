import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bien_detail_sheet.dart';

class ListaBienesScreen extends StatefulWidget {
  @override
  _ListaBienesScreenState createState() => _ListaBienesScreenState();
}

class _ListaBienesScreenState extends State<ListaBienesScreen> {
  String _searchQuery = '';
  String _filterStatus = 'TODOS';
  final _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Bienes"),
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
                
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return _buildBienCard(data);
                  },
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
    
    if (_filterStatus != 'TODOS') {
      query = query.where('status', isEqualTo: _filterStatus);
    }
    
    return query.orderBy('descripcion').snapshots();
  }
  
  Widget _buildBienCard(Map<String, dynamic> bien) {
    final status = bien['status'] ?? 'POR_UBICAR';
    
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
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 28),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bien['descripcion'] ?? 'Sin descripción',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bien['ubicacion'] ?? 'Sin ubicación',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.tag, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          bien['codigo'] ?? bien['id'] ?? 'N/A',
                          style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusShortLabel(status),
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
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
