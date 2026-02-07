import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoMovimientoScreen extends StatefulWidget {
  final Map<String, dynamic>? bienSeleccionado;

  NuevoMovimientoScreen({this.bienSeleccionado});

  @override
  _NuevoMovimientoScreenState createState() => _NuevoMovimientoScreenState();
}

class _NuevoMovimientoScreenState extends State<NuevoMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  String _tipoMovimiento = 'TRANSFERENCIA';
  
  // Controladores para el destino
  final _secretariaController = TextEditingController();
  final _unidadController = TextEditingController();
  final _areaController = TextEditingController();
  final _resguardatarioController = TextEditingController();

  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Movimiento"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoBien(),
                SizedBox(height: 25),
                Text("Tipo de Movimiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                _buildTipoSelector(),
                SizedBox(height: 25),
                Text("Datos de Destino / Nuevo Estado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 15),
                _buildFormFields(),
                SizedBox(height: 40),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBien() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Color(0xFFA62145), size: 40),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.bienSeleccionado?['nombre_bien'] ?? "Seleccione un bien", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("ID: ${widget.bienSeleccionado?['id_bien'] ?? '---'}", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          if (widget.bienSeleccionado == null)
            TextButton(onPressed: () {}, child: Text("BUSCAR", style: TextStyle(color: Color(0xFFA62145))))
        ],
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tipoMovimiento,
          isExpanded: true,
          items: ['TRANSFERENCIA', 'BAJA', 'REASIGNACION'].map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (val) => setState(() => _tipoMovimiento = val!),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    if (_tipoMovimiento == 'BAJA') {
      return TextFormField(
        decoration: InputDecoration(
          labelText: "Motivo de la Baja",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: 3,
      );
    }

    return Column(
      children: [
        _textField("Secretaría Destino", _secretariaController),
        SizedBox(height: 15),
        _textField("Unidad Destino", _unidadController),
        SizedBox(height: 15),
        _textField("Área Destino", _areaController),
        SizedBox(height: 15),
        _textField("Nuevo Resguardatario", _resguardatarioController),
      ],
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.location_city, size: 20),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Campo requerido" : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: _procesando 
          ? CircularProgressIndicator(color: Colors.white)
          : Text("CONFIRMAR MOVIMIENTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      onPressed: _procesando ? null : _ejecutarMovimiento,
    );
  }

  Future<void> _ejecutarMovimiento() async {
    if (!_formKey.currentState!.validate() || widget.bienSeleccionado == null) return;

    setState(() => _procesando = true);

    try {
      /* 
      LÓGICA DE TRANSACCIÓN ATÓMICA (Pseudocódigo para Firestore):
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Referencia al bien
        DocumentReference bienRef = db.collection('bienes').doc(widget.bienSeleccionado['id_bien']);
        
        // 2. Crear el registro en 'movimientos'
        DocumentReference movRef = db.collection('movimientos').doc();
        transaction.set(movRef, {
          'tipo': _tipoMovimiento,
          'fecha': FieldValue.serverTimestamp(),
          'bien_id': widget.bienSeleccionado['id_bien'],
          'origen': widget.bienSeleccionado['ubicacion_actual'],
          'destino': {
            'secretaria': _secretariaController.text,
            'unidad': _unidadController.text,
            'area': _areaController.text,
          },
          'autorizado_por': 'UID_ACTUAL'
        });

        // 3. Actualizar el bien automáticamente
        transaction.update(bienRef, {
          'ubicacion_actual': {
            'secretaria': _secretariaController.text,
            'unidad': _unidadController.text,
            'area': _areaController.text,
          },
          'resguardatario.nombre': _resguardatarioController.text,
          'estatus_verificacion': _tipoMovimiento == 'BAJA' ? 'NO_UBICADO' : 'MOVIMIENTO'
        });
      });
      */

      await Future.delayed(Duration(seconds: 2)); // Simulación

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Movimiento registrado y sincronizado"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _procesando = false);
    }
  }
}
