import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedBackground = 'Default';
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configuración"),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildHeader("Personalización"),
          ListTile(
            leading: Icon(Icons.wallpaper, color: Color(0xFFA62145)),
            title: Text("Fondo de Pantalla"),
            subtitle: Text("Seleccionado: $_selectedBackground"),
            trailing: Icon(Icons.chevron_right),
            onTap: _showBackgroundPicker,
          ),
          Divider(),
          _buildHeader("Sistema"),
          SwitchListTile(
            secondary: Icon(Icons.notifications, color: Color(0xFFA62145)),
            title: Text("Notificaciones de Verificación"),
            subtitle: Text("Alertar cuando un bien requiere revisión"),
            value: _notificationsEnabled,
            activeColor: Color(0xFFA62145),
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          ListTile(
            leading: Icon(Icons.cloud_sync, color: Color(0xFFA62145)),
            title: Text("Sincronización Manual"),
            subtitle: Text("Forzar actualización de datos locales"),
            onTap: () {
              // Lógica de sincronización
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sincronizando con Firestore...")));
            },
          ),
          Divider(),
          _buildHeader("Usuario"),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.grey),
            title: Text("Cerrar Sesión"),
            onTap: () {
              // Auth logout
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showBackgroundPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Selecciona un Fondo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _bgOption('Moderno', Colors.blueGrey),
                    _bgOption('Clásico', Color(0xFFA62145)),
                    _bgOption('Luz', Colors.white),
                    _bgOption('Oscuro', Colors.black87),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bgOption(String name, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBackground = name);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fondo actualizado a $name")));
      },
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
          SizedBox(height: 5),
          Text(name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
