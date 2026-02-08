import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Navegar al Dashboard después de login exitoso
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No existe una cuenta con este correo.';
            break;
          case 'wrong-password':
            _errorMessage = 'Contraseña incorrecta.';
            break;
          case 'invalid-email':
            _errorMessage = 'Correo electrónico inválido.';
            break;
          case 'user-disabled':
            _errorMessage = 'Esta cuenta ha sido deshabilitada.';
            break;
          default:
            _errorMessage = 'Error de autenticación: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión. Intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Cabecera con Curva
              Stack(
                children: [
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFA62145), Color(0xFF7D1632)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(80),
                        bottomRight: Radius.circular(80),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 10,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Hero(
                          tag: 'logo',
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                            ),
                            child: Icon(Icons.lock_person, size: 50, color: Color(0xFFA62145)),
                          ),
                        ),
                        SizedBox(height: 15),
                        Text("INGRESO ADMIN (DEV)", 
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)
                        ),
                        Text("SICOPA v1.0", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(35.0),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                          ],
                        ),
                      ),
                    
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa tu correo';
                        if (!value.contains('@')) return 'Correo inválido';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Correo Institucional",
                        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFA62145)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Color(0xFFA62145), width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                        if (value.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFA62145)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Color(0xFFA62145), width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showResetPasswordDialog(),
                        child: Text("¿Olvidaste tu contraseña?", style: TextStyle(color: Color(0xFFA62145))),
                      ),
                    ),
                    SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFA62145),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("INICIAR SESIÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    // Botón temporal visible
                    TextButton(
                      onPressed: _showRegisterDialog,
                      child: Text("Registrar Admin (Inicial)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),

                    SizedBox(height: 20),
                    Text("¿No tienes cuenta?", style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Contacta al administrador para solicitar acceso.")),
                        );
                      },
                      child: Text("Solicitar acceso", style: TextStyle(color: Color(0xFFA62145), fontWeight: FontWeight.bold)),
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
  
  void _showRegisterDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Crear Admin Inicial"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Nombre completo")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Correo electrónico")),
              TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: "Contraseña (min 6)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty || passwordController.text.length < 6) return;
              try {
                // Crear usuario
                final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                );
                
                // Guardar rol de admin
                if (cred.user != null) {
                  await FirebaseFirestore.instance.collection('usuarios').doc(cred.user!.uid).set({
                    'nombre': nameController.text.isEmpty ? 'Administrador' : nameController.text,
                    'email': emailController.text.trim(),
                    'rol': 'ADMINISTRADOR',
                    'fechaRegistro': FieldValue.serverTimestamp(),
                  });
                }
                
                Navigator.pop(context); // Cerrar diálogo
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("¡Admin creado! Iniciando sesión..."), backgroundColor: Colors.green),
                );
                
                // Navegar al Dashboard
                if (mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
                }
                
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: Text("Registrar Admin"),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Recuperar Contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña."),
            SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA62145)),
            onPressed: () async {
              if (resetEmailController.text.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmailController.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Correo de recuperación enviado."), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al enviar correo."), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text("Enviar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
