
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bienes/lista_bienes_screen.dart';
import '../verificacion_screen.dart';

class ServidoresScreen extends StatefulWidget {
  final String? filterAreaNombre;
  
  const ServidoresScreen({Key? key, this.filterAreaNombre}) : super(key: key);

  @override
  _ServidoresScreenState createState() => _ServidoresScreenState();
}

class _ServidoresScreenState extends State<ServidoresScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filterAreaNombre != null 
          ? "Personal de ${widget.filterAreaNombre}" 
          : "Servidores Públicos"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: "Ir al Inicio",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toUpperCase()),
              decoration: InputDecoration(
                hintText: "Buscar servidor...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.filterAreaNombre != null
                ? FirebaseFirestore.instance.collection('bienes')
                    .where('area', isEqualTo: widget.filterAreaNombre!.toUpperCase())
                    .snapshots()
                : FirebaseFirestore.instance.collection('bienes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error al cargar datos"));
                }

                // Extraer servidores y sus estadísticas
                final docs = snapshot.data?.docs ?? [];
                final Map<String, Map<String, int>> statsServidores = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['servidorPublico'] ?? data['resguardatario'] ?? 'DESCONOCIDO').toString().toUpperCase().trim();
                  final status = data['status'] ?? 'POR_UBICAR';
                  
                  if (nombre.isNotEmpty) {
                    if (!statsServidores.containsKey(nombre)) {
                      statsServidores[nombre] = {
                        'total': 0,
                        'UBICADO': 0,
                        'MOVIMIENTO': 0,
                        'NO_UBICADO': 0,
                        'POR_UBICAR': 0,
                      };
                    }
                    statsServidores[nombre]!['total'] = statsServidores[nombre]!['total']! + 1;
                    statsServidores[nombre]![status] = (statsServidores[nombre]![status] ?? 0) + 1;
                  }
                }

                final sortedServidores = statsServidores.keys
                    .where((n) => n.contains(_searchQuery))
                    .toList()..sort();

                if (sortedServidores.isEmpty) {
                  return Center(child: Text("No se encontraron servidores."));
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedServidores.length,
                  itemBuilder: (context, index) {
                    final nombre = sortedServidores[index];
                    final stats = statsServidores[nombre]!;
                    final total = stats['total'];
                    final ubicados = stats['UBICADO'];

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFA62145).withOpacity(0.1),
                          child: Icon(Icons.person, color: Color(0xFFA62145)),
                        ),
                        title: Text(nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text("$total bienes asignados", style: TextStyle(fontSize: 13)),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _StatusBadge(label: "Ubicados", count: ubicados!, color: Colors.green),
                                _StatusBadge(label: "Pendientes", count: total! - ubicados, color: Colors.amber),
                                if (stats['NO_UBICADO']! > 0)
                                  _StatusBadge(label: "No Ubicados", count: stats['NO_UBICADO']!, color: Colors.red),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.qr_code_scanner, color: Color(0xFFA62145)),
                              tooltip: "Verificar bienes de este servidor",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerificacionScreen(
                                      filterServidorNombre: nombre,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListaBienesScreen(
                                filterServidorNombre: nombre,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0 && label != "Ubicados") return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "$count $label",
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
