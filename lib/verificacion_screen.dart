import 'package:flutter/material.dart';
// Nota: Estas librerías deben agregarse al pubspec.yaml
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:nfc_manager/nfc_manager.dart';

class VerificacionScreen extends StatefulWidget {
  @override
  _VerificacionScreenState createState() => _VerificacionScreenState();
}

class _VerificacionScreenState extends State<VerificacionScreen> {
  String _estatusActual = 'POR_UBICAR'; // Estatus inicial

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Escáner de Bienes"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Área del Escáner (Placeholder para MobileScanner)
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Color(0xFFA62145), width: 3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 60),
                    SizedBox(height: 10),
                    Text("Cámara Activa (QR / Barcode)", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          
          // Panel de Información y Semáforo
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text("Estatus de Verificación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  _semaforo(_estatusActual),
                  SizedBox(height: 30),
                  
                  // Botón de lectura NFC (Simbolismo)
                  ElevatedButton.icon(
                    icon: Icon(Icons.nfc),
                    label: Text("ESPERANDO LECTURA NFC..."),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      // Iniciar sesión NFC: NfcManager.instance.startSession(...)
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Semáforo Visual Premium
  Widget _semaforo(String estado) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circuloColor(Colors.green, "UBICADO", estado == 'UBICADO'),
          _circuloColor(Colors.blue, "MOVIMIENTO", estado == 'MOVIMIENTO'),
          _circuloColor(Colors.amber, "POR UBICAR", estado == 'POR_UBICAR'),
          _circuloColor(Colors.red, "NO UBICADO", estado == 'NO_UBICADO'),
        ],
      ),
    );
  }

  Widget _circuloColor(Color color, String label, bool activo) {
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: activo ? 55 : 35,
          height: activo ? 55 : 35,
          decoration: BoxDecoration(
            color: activo ? color : color.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: activo ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] : [],
            border: Border.all(color: activo ? Colors.white : Colors.transparent, width: 2),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label, 
          style: TextStyle(
            fontSize: 10, 
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            color: activo ? Colors.black87 : Colors.black38
          )
        ),
      ],
    );
  }
}
