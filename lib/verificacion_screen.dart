import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/bien_detail_sheet.dart';

class VerificacionScreen extends StatefulWidget {
  final String? filterServidorNombre;
  final String? filterAreaNombre;
  final String? filterUnidadNombre;
  final String? filterSecretariaNombre;

  const VerificacionScreen({
    Key? key,
    this.filterServidorNombre,
    this.filterAreaNombre,
    this.filterUnidadNombre,
    this.filterSecretariaNombre,
  }) : super(key: key);

  @override
  _VerificacionScreenState createState() => _VerificacionScreenState();
}

class _VerificacionScreenState extends State<VerificacionScreen> {
  MobileScannerController? _cameraController;
  String _estatusActual = 'ESPERANDO';
  bool _isProcessing = false;
  bool _isScannerActive = true; 
  Map<String, dynamic>? _bienEncontrado;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ... (otros métodos) ...

  void _showBienDetails() {
    if (_bienEncontrado == null) return;
    
    // Detener escáner temporalmente para liberar la cámara
    setState(() => _isScannerActive = false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BienDetailSheet(
        bien: _bienEncontrado!,
        onStatusChanged: (newStatus) async {
          await _updateBienStatus(newStatus);
        },
      ),
    ).whenComplete(() {
      // Reactivar escáner al cerrar 
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isScannerActive = true);
      });
    });
  }

  Future<void> _buscarPorInventario(String idOInventario) async {
    setState(() {
      _isProcessing = true;
      _estatusActual = 'BUSCANDO';
    });

    try {
      // Intentamos buscar por varios campos
      QuerySnapshot queryInv = await FirebaseFirestore.instance
          .collection('bienes')
          .where('inventario', isEqualTo: idOInventario)
          .limit(1)
          .get();

      if (queryInv.docs.isNotEmpty) {
        final doc = queryInv.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        setState(() {
          _bienEncontrado = data;
          _estatusActual = data['status'] ?? 'POR_UBICAR';
        });
        _validarFiltro(data);
        _showBienDetails();
        return;
      }

      QuerySnapshot queryCod = await FirebaseFirestore.instance
          .collection('bienes')
          .where('codigo', isEqualTo: idOInventario)
          .limit(1)
          .get();

      if (queryCod.docs.isNotEmpty) {
        final doc = queryCod.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        setState(() {
          _bienEncontrado = data;
          _estatusActual = data['status'] ?? 'POR_UBICAR';
        });
        _validarFiltro(data);
        _showBienDetails();
        return;
      }

      final docRef = await FirebaseFirestore.instance.collection('bienes').doc(idOInventario).get();
      if (docRef.exists) {
        final data = docRef.data()!;
        data['id'] = docRef.id;
        setState(() {
          _bienEncontrado = data;
          _estatusActual = data['status'] ?? 'POR_UBICAR';
        });
        _validarFiltro(data);
        _showBienDetails();
      } else {
        setState(() {
          _estatusActual = 'NO_ENCONTRADO';
          _bienEncontrado = null;
        });
        _showNotFoundDialog(idOInventario);
      }
    } catch (e) {
      setState(() => _estatusActual = 'ERROR');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  bool _validarFiltro(Map<String, dynamic> data) {
    bool passed = true;
    String? errorMsg;

    if (widget.filterServidorNombre != null) {
      final actual = (data['servidorPublico'] ?? '').toString().toUpperCase();
      final expected = widget.filterServidorNombre!.toUpperCase();
      if (actual != expected) {
        passed = false;
        errorMsg = "Este bien pertenece a\n$actual\ny no a ${widget.filterServidorNombre}";
      }
    } else if (widget.filterAreaNombre != null) {
      final actual = (data['area'] ?? '').toString().toUpperCase();
      final expected = widget.filterAreaNombre!.toUpperCase();
      if (actual != expected) {
        passed = false;
        errorMsg = "Este bien pertenece al área\n$actual\ny no a ${widget.filterAreaNombre}";
      }
    }
    // Añadir más si es necesario

    if (!passed) {
      _showFilterWarning(errorMsg!);
    }
    return passed;
  }

  void _showFilterWarning(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Aviso de Ubicación"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("IGNORAR Y VER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA62145)),
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              setState(() {
                _bienEncontrado = null;
                _estatusActual = 'ESPERANDO';
              });
            },
            child: Text("CANCELAR"),
          ),
        ],
      ),
    );
  }

  void _mostrarBusquedaManual() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Búsqueda Manual"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Número de Inventario",
            hintText: "Escribe el código o inventario...",
            prefixIcon: Icon(Icons.edit),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty) _buscarPorInventario(value.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA62145)),
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) _buscarPorInventario(controller.text.trim());
            },
            child: Text("Buscar"),
          ),
        ],
      ),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final code = barcode.rawValue!;
    if (code == _lastScannedCode) return;
    _lastScannedCode = code;
    await _buscarPorInventario(code);
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) setState(() => _lastScannedCode = null);
    });
  }


  
  Future<void> _updateBienStatus(String newStatus) async {
    if (_bienEncontrado == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('bienes')
          .doc(_bienEncontrado!['id'])
          .update({
            'status': newStatus,
            'ultimaVerificacion': FieldValue.serverTimestamp(),
          });
      setState(() => _estatusActual = newStatus);
      await FirebaseFirestore.instance.collection('movimientos').add({
        'bienId': _bienEncontrado!['id'],
        'descripcionBien': _bienEncontrado!['descripcion'] ?? 'Sin descripción',
        'tipoMovimiento': 'VERIFICACION',
        'nuevoEstatus': newStatus,
        'fecha': FieldValue.serverTimestamp(),
        'observaciones': 'Verificación por escaneo',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Estado actualizado a $newStatus"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar: $e"), backgroundColor: Colors.red),
      );
    }
  }
  
  void _showNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.search_off, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text("Bien No Encontrado"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("El código escaneado no corresponde a ningún bien registrado en el sistema."),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(child: Text(code, style: TextStyle(fontFamily: 'monospace'))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cerrar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verificar Bien"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: "Ir al Inicio",
          ),
          IconButton(
            icon: Icon(Icons.keyboard),
            tooltip: "Entrada Manual",
            onPressed: _mostrarBusquedaManual,
          ),
          IconButton(
            icon: Icon(_cameraController?.torchEnabled == true ? Icons.flash_on : Icons.flash_off),
            onPressed: () => _cameraController?.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: () => _cameraController?.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
        if (widget.filterServidorNombre != null || 
            widget.filterAreaNombre != null || 
            widget.filterUnidadNombre != null || 
            widget.filterSecretariaNombre != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.person_pin, size: 16, color: Colors.amber.shade900),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Verificando: ${widget.filterServidorNombre ?? widget.filterAreaNombre ?? widget.filterUnidadNombre ?? widget.filterSecretariaNombre}",
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFFA62145), width: 3),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  if (_isScannerActive)
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: _onBarcodeDetected,
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Text("Cámara Pausada", style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                  
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Column(
                children: [
                  Text("Estatus de Verificación", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),
                  _buildSemaforo(_estatusActual),
                  SizedBox(height: 20),
                  if (_bienEncontrado != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.inventory_2, color: Color(0xFFA62145)),
                        title: Text(_bienEncontrado!['descripcion'] ?? 'Sin descripción', 
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text("ID: ${_bienEncontrado!['id']}", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        onTap: _showBienDetails,
                      ),
                    )
                  else
                    Text("Escanea un código QR o de barras", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFFA62145),
        icon: Icon(Icons.edit_note),
        label: Text("Inspección Manual"),
        onPressed: _mostrarBusquedaManual,
      ),
    );
  }

  Widget _buildSemaforo(String estado) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCirculoEstado(Colors.green, "UBICADO", estado == 'UBICADO'),
        _buildCirculoEstado(Colors.blue, "MOVIMIENTO", estado == 'MOVIMIENTO'),
        _buildCirculoEstado(Colors.amber, "POR UBICAR", estado == 'POR_UBICAR' || estado == 'ESPERANDO'),
        _buildCirculoEstado(Colors.red, "NO UBICADO", estado == 'NO_UBICADO' || estado == 'NO_ENCONTRADO'),
      ],
    );
  }

  Widget _buildCirculoEstado(Color color, String label, bool activo) {
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: activo ? 50 : 35,
          height: activo ? 50 : 35,
          decoration: BoxDecoration(
            color: activo ? color : color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: activo ? Colors.white : Colors.transparent, width: 2),
          ),
          child: activo ? Icon(Icons.check, color: Colors.white, size: 24) : null,
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 9, color: activo ? Colors.black87 : Colors.black38)),
      ],
    );
  }
}
