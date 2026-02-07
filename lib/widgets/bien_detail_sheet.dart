import 'package:flutter/material.dart';

class BienDetailSheet extends StatelessWidget {
  final Map<String, dynamic> bien;

  BienDetailSheet({required this.bien});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(bien['estatus_verificacion'] ?? 'UBICADO'),
              IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SizedBox(height: 15),
          Text(bien['nombre_bien'] ?? "Sin nombre", 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
          ),
          Text("Folio Inventario: ${bien['id_bien']}", 
            style: TextStyle(color: Colors.grey[600], fontSize: 14)
          ),
          Divider(height: 40),
          _infoRow(Icons.person, "Resguardatario", bien['resguardatario_nombre'] ?? "N/A"),
          _infoRow(Icons.business, "Secretaría", bien['secretaria'] ?? "N/A"),
          _infoRow(Icons.location_on, "Área Actual", bien['area'] ?? "N/A"),
          _infoRow(Icons.fingerprint, "NFC ID", bien['nfc_id'] ?? "No registrado"),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: Color(0xFFA62145)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: Text("VER HISTORIAL", style: TextStyle(color: Color(0xFFA62145))),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA62145),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: Text("TRANSFERIR", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.green;
    if (status == 'MOVIMIENTO') color = Colors.blue;
    if (status == 'POR_UBICAR') color = Colors.orange;
    if (status == 'NO_UBICADO') color = Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
