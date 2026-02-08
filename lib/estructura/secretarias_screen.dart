import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unidades_screen.dart';
import '../bienes/lista_bienes_screen.dart';
import '../verificacion_screen.dart';

class SecretariasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Estructura - Secretarías"),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('secretarias').orderBy('nombre').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Text("No hay Secretarías registradas."));
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
                    backgroundColor: Color(0xFFA62145).withOpacity(0.1),
                    child: Icon(Icons.account_balance, color: Color(0xFFA62145)),
                  ),
                  title: Text(nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.inventory_2, color: Color(0xFFA62145), size: 20),
                        tooltip: "Ver Bienes",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListaBienesScreen(
                                filterSecretariaNombre: nombre.toUpperCase(),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: Color(0xFFA62145), size: 20),
                        tooltip: "Verificar Bienes",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerificacionScreen(
                                filterSecretariaNombre: nombre.toUpperCase(),
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
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnidadesScreen(
                          secretariaId: doc.id,
                          secretariaNombre: nombre,
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
        title: Text("Nueva Secretaría"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Nombre de la Secretaría",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA62145)),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('secretarias').add({
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
         title: Text("Editar Secretaría"),
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
         content: Text("¿Estás seguro de eliminar esta Secretaría? Esta acción no se puede deshacer y borrará también sus unidades y áreas."),
         actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
            TextButton(
              onPressed: () async {
                 await FirebaseFirestore.instance
                        .collection('secretarias')
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
