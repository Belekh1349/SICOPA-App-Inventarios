import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bienes/lista_bienes_screen.dart';
import '../verificacion_screen.dart';
import 'servidores_screen.dart';

class AreasScreen extends StatelessWidget {
  final String secretariaId;
  final String unidadId;
  final String unidadNombre;

  const AreasScreen({
    Key? key,
    required this.secretariaId,
    required this.unidadId,
    required this.unidadNombre,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Áreas de Adscripción"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: "Ir al Inicio",
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerificacionScreen(
                    filterUnidadNombre: unidadNombre.toUpperCase(),
                  ),
                ),
              );
            },
            tooltip: "Verificar Bienes de esta Unidad",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('secretarias')
            .doc(secretariaId)
            .collection('unidades')
            .doc(unidadId)
            .collection('areas')
            .orderBy('nombre')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Text("No hay Áreas registradas en esta Unidad."));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] ?? 'Sin Nombre';

              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.withOpacity(0.1),
                    child: Icon(Icons.people, color: Colors.amber[800]),
                  ),
                  title: Text(nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: _AreaProgressIndicator(areaNombre: nombre),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.inventory_2, color: Color(0xFFA62145), size: 20),
                        tooltip: "Ver Personal y Bienes",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServidoresScreen(
                                filterAreaNombre: nombre,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: Color(0xFFA62145), size: 20),
                        tooltip: "Verificar bienes de esta área",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerificacionScreen(
                                filterAreaNombre: nombre.toUpperCase(),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _mostrarDialogoEditar(context, doc.id, nombre),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _confirmarEliminar(context, doc.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    _mostrarOpcionesArea(context, doc.id, nombre);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFA62145),
        child: Icon(Icons.add),
        onPressed: () => _mostrarDialogoAgregar(context),
      ),
    );
  }

  void _mostrarOpcionesArea(BuildContext context, String areaId, String nombreArea) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(nombreArea, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.people, color: Color(0xFFA62145)),
                title: Text("Ver Personal Asignado"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServidoresScreen(
                        filterAreaNombre: nombreArea,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.list, color: Colors.blue),
                title: Text("Ver Todos los Bienes"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListaBienesScreen(
                        filterAreaNombre: nombreArea.toUpperCase(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _mostrarDialogoAgregar(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Nueva Área"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Nombre del Área",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA62145)),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('secretarias')
                    .doc(secretariaId)
                    .collection('unidades')
                    .doc(unidadId)
                    .collection('areas')
                    .add({
                  'nombre': controller.text.trim(),
                  'fechaCreacion': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(BuildContext context, String docId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
         title: Text("Editar Área"),
         content: TextField(controller: controller, decoration: InputDecoration(labelText: "Nombre")),
         actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                 if (controller.text.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('secretarias')
                        .doc(secretariaId)
                        .collection('unidades')
                        .doc(unidadId)
                        .collection('areas')
                        .doc(docId)
                        .update({'nombre': controller.text.trim()});
                    Navigator.pop(context);
                 }
              },
              child: Text("Actualizar"),
            )
         ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
         title: Text("Confirmar Eliminación"),
         content: Text("¿Estás seguro de eliminar esta área? Esta acción no se puede deshacer."),
         actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
            TextButton(
              onPressed: () async {
                 await FirebaseFirestore.instance
                        .collection('secretarias')
                        .doc(secretariaId)
                        .collection('unidades')
                        .doc(unidadId)
                        .collection('areas')
                        .doc(docId)
                        .delete();
                 Navigator.pop(context);
              },
              child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            )
         ],
      ),
    );
  }
}

class _AreaProgressIndicator extends StatelessWidget {
  final String areaNombre;

  const _AreaProgressIndicator({required this.areaNombre});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bienes')
          .where('area', isEqualTo: areaNombre.toUpperCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        final docs = snapshot.data!.docs;
        final total = docs.length;
        if (total == 0) return Text("Sin bienes asignados", style: TextStyle(fontSize: 12));

        final ubicados = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'UBICADO';
        }).length;

        final porcentaje = ubicados / total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Text("Progreso: $ubicados/$total", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                SizedBox(width: 8),
                Text("${(porcentaje * 100).toInt()}%", 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA62145))
                ),
              ],
            ),
            SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: porcentaje,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  porcentaje == 1.0 ? Colors.green : Color(0xFFA62145)
                ),
                minHeight: 4,
              ),
            ),
          ],
        );
      },
    );
  }
}
