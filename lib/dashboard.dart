import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'verificacion_screen.dart';
import 'movimientos/historial_screen.dart';
import 'movimientos/nuevo_movimiento_screen.dart';
import 'admin/respaldo_screen.dart';
import 'bienes/lista_bienes_screen.dart';
import 'reportes/reportes_screen.dart';
import 'estructura/secretarias_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isGuest;
  
  DashboardScreen({this.isGuest = false});
  
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _userName;
  String? _userRole;
  
  // Estadísticas del inventario
  int _totalBienes = 0;
  int _ubicados = 0;
  int _enMovimiento = 0;
  int _noUbicados = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
  }
  
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['nombre'] ?? user.email?.split('@')[0] ?? 'Usuario';
          _userRole = doc.data()?['rol'] ?? 'VERIFICADOR';
        });
      } else if (mounted) {
        setState(() {
          _userName = user.email?.split('@')[0] ?? 'Usuario';
          _userRole = 'VERIFICADOR';
        });
      }
    }
  }
  
  Future<void> _loadStatistics() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('bienes').get();
      
      int ubicados = 0;
      int enMovimiento = 0;
      int noUbicados = 0;
      
      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'POR_UBICAR';
        switch (status) {
          case 'UBICADO':
            ubicados++;
            break;
          case 'MOVIMIENTO':
            enMovimiento++;
            break;
          case 'NO_UBICADO':
            noUbicados++;
            break;
          default:
            noUbicados++;
        }
      }
      
      if (mounted) {
        setState(() {
          _totalBienes = snapshot.docs.length;
          _ubicados = ubicados;
          _enMovimiento = enMovimiento;
          _noUbicados = noUbicados;
        });
      }
    } catch (e) {
      // En caso de error, usar valores demo
      if (mounted) {
        setState(() {
          _totalBienes = 150;
          _ubicados = 138;
          _enMovimiento = 7;
          _noUbicados = 5;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double porcentajeUbicados = _totalBienes > 0 ? (_ubicados / _totalBienes * 100) : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Panel de Control", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFA62145),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadStatistics();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Actualizando estadísticas..."), duration: Duration(seconds: 1)),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle, size: 28),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              } else if (value == 'profile') {
                _showProfileDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFFA62145)),
                    SizedBox(width: 10),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header con estadísticas
              Container(
                padding: EdgeInsets.fromLTRB(20, 15, 20, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA62145), Color(0xFF7D1632)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hola, ${widget.isGuest ? 'Invitado' : _userName ?? 'Usuario'}",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.isGuest ? 'Modo Solo Lectura' : _userRole ?? 'VERIFICADOR',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Text("Estado Global del Inventario", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("${porcentajeUbicados.toStringAsFixed(0)}%", "Ubicados", Icons.check_circle, Colors.greenAccent),
                        _buildStatItem("$_enMovimiento", "En Movimiento", Icons.sync, Colors.lightBlueAccent),
                        _buildStatItem("$_noUbicados", "Faltantes", Icons.error_outline, Colors.orangeAccent),
                        _buildStatItem("$_totalBienes", "Total", Icons.inventory, Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Grid de menú
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Módulos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 15),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 3, // Más columnas para hacerlos más pequeños
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                      children: [
                        _buildMenuCard(context, "Verificar Bien", Icons.qr_code_scanner, Color(0xFF1976D2), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => VerificacionScreen()));
                        }),
                        _buildMenuCard(context, "Dependencias", Icons.domain, Color(0xFF5C6BC0), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SecretariasScreen()));
                        }),
                        _buildMenuCard(context, "Nuevo Movimiento", Icons.swap_horiz, Color(0xFFFF9800), () {
                          if (widget.isGuest) {
                            _showGuestRestriction();
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => NuevoMovimientoScreen()));
                          }
                        }),
                        _buildMenuCard(context, "Lista de Bienes", Icons.inventory_2, Color(0xFF4CAF50), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ListaBienesScreen()));
                        }),
                        _buildMenuCard(context, "Historial", Icons.history, Color(0xFF9C27B0), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialScreen()));
                        }),
                        _buildMenuCard(context, "Reportes", Icons.insert_chart, Color(0xFFE91E63), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ReportesScreen()));
                        }),
                        _buildMenuCard(context, "Carga Masiva", Icons.cloud_upload, Color(0xFF00BCD4), () {
                          if (widget.isGuest) {
                            _showGuestRestriction();
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => RespaldoScreen()));
                          }
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        SizedBox(height: 5),
        Text(val, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, String titulo, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10), // Padding reducido
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color), // Icono más pequeño
              ),
              SizedBox(height: 12),
              Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showGuestRestriction() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Esta función requiere iniciar sesión."),
        action: SnackBarAction(
          label: "Iniciar Sesión",
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cerrar Sesión"),
        content: Text("¿Estás seguro que deseas salir?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text("Salir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Color(0xFFA62145), size: 30),
            SizedBox(width: 10),
            Text("Mi Perfil"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileRow("Nombre", _userName ?? 'Usuario'),
            _profileRow("Correo", user?.email ?? 'N/A'),
            _profileRow("Rol", _userRole ?? 'VERIFICADOR'),
            _profileRow("UID", user?.uid.substring(0, 8) ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cerrar")),
        ],
      ),
    );
  }
  
  Widget _profileRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text("$label:", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
