import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoMovimientoScreen extends StatefulWidget {
  final String? bienId;
  
  NuevoMovimientoScreen({this.bienId});
  
  @override
  _NuevoMovimientoScreenState createState() => _NuevoMovimientoScreenState();
}

class _NuevoMovimientoScreenState extends State<NuevoMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  final _ubicacionDestinoController = TextEditingController();
  
  String _tipoMovimiento = 'TRASLADO';
  String? _selectedBienId;
  Map<String, dynamic>? _selectedBien;
  bool _isLoading = false;
  bool _isSearching = false;
  List<DocumentSnapshot> _bienesList = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.bienId != null) {
      _loadBien(widget.bienId!);
    }
    _loadBienes();
  }
  
  Future<void> _loadBienes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bienes')
        .orderBy('descripcion')
        .limit(50)
        .get();
    
    if (mounted) {
      setState(() => _bienesList = snapshot.docs);
    }
  }
  
  Future<void> _loadBien(String bienId) async {
    final doc = await FirebaseFirestore.instance.collection('bienes').doc(bienId).get();
    if (doc.exists && mounted) {
      setState(() {
        _selectedBienId = bienId;
        _selectedBien = doc.data();
        _selectedBien!['id'] = doc.id;
      });
    }
  }

  Future<void> _guardarMovimiento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBien == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selecciona un bien"), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Crear el movimiento
      await FirebaseFirestore.instance.collection('movimientos').add({
        'bienId': _selectedBienId,
        'descripcionBien': _selectedBien!['descripcion'] ?? 'Sin descripción',
        'tipoMovimiento': _tipoMovimiento,
        'ubicacionOrigen': _selectedBien!['ubicacion'] ?? 'Sin ubicación',
        'ubicacionDestino': _ubicacionDestinoController.text,
        'observaciones': _observacionesController.text,
        'fecha': FieldValue.serverTimestamp(),
      });
      
      // Actualizar el bien según el tipo de movimiento
      Map<String, dynamic> updateData = {};
      
      switch (_tipoMovimiento) {
        case 'TRASLADO':
          updateData = {
            'status': 'MOVIMIENTO',
            'ubicacion': _ubicacionDestinoController.text,
            'ultimaVerificacion': FieldValue.serverTimestamp(),
          };
          break;
        case 'VERIFICACION':
          updateData = {
            'status': 'UBICADO',
            'ultimaVerificacion': FieldValue.serverTimestamp(),
          };
          break;
        case 'BAJA':
          updateData = {
            'status': 'BAJA',
            'fechaBaja': FieldValue.serverTimestamp(),
          };
          break;
        case 'PRESTAMO':
          updateData = {
            'status': 'MOVIMIENTO',
            'enPrestamo': true,
            'destinoPrestamo': _ubicacionDestinoController.text,
          };
          break;
      }
      
      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('bienes')
            .doc(_selectedBienId)
            .update(updateData);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Movimiento registrado exitosamente"), backgroundColor: Colors.green),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nuevo Movimiento"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de tipo de movimiento
              Text("Tipo de Movimiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildTipoChip('TRASLADO', 'Traslado', Icons.swap_horiz, Colors.blue),
                  _buildTipoChip('VERIFICACION', 'Verificación', Icons.verified, Colors.green),
                  _buildTipoChip('BAJA', 'Baja', Icons.remove_circle, Colors.red),
                  _buildTipoChip('PRESTAMO', 'Préstamo', Icons.assignment_return, Colors.orange),
                ],
              ),
              
              SizedBox(height: 25),
              
              // Selector de bien
              Text("Bien Patrimonial *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              
              if (_selectedBien != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.inventory_2, color: Color(0xFFA62145)),
                    title: Text(_selectedBien!['descripcion'] ?? 'Sin descripción'),
                    subtitle: Text(_selectedBien!['ubicacion'] ?? 'Sin ubicación'),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => setState(() {
                        _selectedBien = null;
                        _selectedBienId = null;
                      }),
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: _showBienSelector,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 12),
                        Text("Buscar y seleccionar bien...", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              
              SizedBox(height: 25),
              
              // Ubicación destino (para traslados y préstamos)
              if (_tipoMovimiento == 'TRASLADO' || _tipoMovimiento == 'PRESTAMO') ...[
                Text("Ubicación Destino *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                TextFormField(
                  controller: _ubicacionDestinoController,
                  validator: (value) {
                    if ((_tipoMovimiento == 'TRASLADO' || _tipoMovimiento == 'PRESTAMO') && 
                        (value == null || value.isEmpty)) {
                      return 'Ingresa la ubicación destino';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Ej: Edificio A, Piso 3, Oficina 301',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 25),
              ],
              
              // Observaciones
              Text("Observaciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              TextFormField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notas adicionales sobre el movimiento...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA62145),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                  ),
                  onPressed: _isLoading ? null : _guardarMovimiento,
                  child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 10),
                          Text("REGISTRAR MOVIMIENTO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTipoChip(String value, String label, IconData icon, Color color) {
    final isSelected = _tipoMovimiento == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : color),
          SizedBox(width: 6),
          Text(label),
        ],
      ),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (selected) {
        if (selected) setState(() => _tipoMovimiento = value);
      },
    );
  }
  
  void _showBienSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    onChanged: (value) {
                      // Implementar búsqueda en tiempo real
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar bien...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _bienesList.length,
                itemBuilder: (context, index) {
                  final doc = _bienesList[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Icon(Icons.inventory_2, color: Color(0xFFA62145)),
                    title: Text(data['descripcion'] ?? 'Sin descripción'),
                    subtitle: Text(data['ubicacion'] ?? 'Sin ubicación'),
                    onTap: () {
                      setState(() {
                        _selectedBienId = doc.id;
                        _selectedBien = data;
                        _selectedBien!['id'] = doc.id;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
