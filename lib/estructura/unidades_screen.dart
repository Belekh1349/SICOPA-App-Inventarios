import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'areas_screen.dart';

class UnidadesScreen extends StatelessWidget {
  final String secretariaId;
  final String secretariaNombre;

  const UnidadesScreen({
    Key? key,
    required this.secretariaId,
    required this.secretariaNombre,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Unidades Administrativas"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('secretarias')
            .doc(secretariaId)
            .collection('unidades')
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
            return Center(child: Text("No hay Unidades registradas en esta Secretaría."));
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
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(Icons.business, color: Colors.blue),
                  ),
                  title: Text(nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _mostrarDialogoEditar(context, doc.id, nombre),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _confirmarEliminar(context, doc.id),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AreasScreen(
                          secretariaId: secretariaId,
                          unidadId: doc.id,
                          unidadNombre: nombre,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFA62145),
        child: Icon(Icons.add),
        onPressed: () => _mostrarDialogoAgregar(context),
      ),
    );
  }

  void _mostrarDialogoAgregar(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Nueva Unidad"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Nombre de la Unidad",
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
         title: Text("Editar Unidad"),
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
         content: Text("¿Estás seguro de eliminar esta Unidad? Esta acción no se puede deshacer y borrará también sus áreas."),
         actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
            TextButton(
              onPressed: () async {
                 await FirebaseFirestore.instance
                        .collection('secretarias')
                        .doc(secretariaId)
                        .collection('unidades')
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
