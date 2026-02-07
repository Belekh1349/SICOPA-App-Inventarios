# SICOPA - Sistema de Control Patrimonial

SICOPA es una solución tecnológica avanzada diseñada para la gestión, verificación y trazabilidad de los bienes muebles del **Gobierno del Estado de México**.

## 🚀 Características Principales

*   **Verificación Híbrida:** Soporte para lectura de códigos QR, códigos de barras y etiquetas NFC.
*   **Diseño Premium:** Interfaz minimalista y elegante con estética institucional y animaciones asimétricas.
*   **Roles y Seguridad:** Sistema de permisos robusto (Admin Supremo y Verificador) con historial de movimientos inviolable.
*   **Reportes Oficiales:** Generación automática de reportes en PDF con sellos institucionales y firmas de responsabilidad.
*   **Carga Masiva:** Módulo de administración para procesar miles de registros vía CSV en segundos.
*   **Modo Offline:** Diseñado para funcionar en campo sin necesidad de conexión constante.

## 🛠️ Stack Tecnológico

*   **Frontend:** Flutter (iOS, Android, Web, PC/Mac).
*   **Backend:** Firebase (Cloud Firestore, Cloud Functions, Firebase Auth).
*   **Lógica de Reportes:** Node.js (pdfmake).

## 📂 Estructura del Proyecto

*   `/lib`: Código fuente de la aplicación Flutter.
*   `/functions`: Lógica de servidor para generación de reportes y carga masiva.
*   `firestore.rules`: Reglas de seguridad de la base de datos.
*   `database_blueprint.json`: Esquema técnico de la colección de datos.

## 📝 Instalación

1. Clonar el repositorio.
2. Ejecutar `flutter pub get` en la raíz.
3. Configurar el proyecto de Firebase y descargar `google-services.json` / `GoogleService-Info.plist`.
4. Implementar las Cloud Functions ejecutando `firebase deploy --only functions`.

---
**Desarrollado para la Subcoordinación de Adquisiciones y Control Patrimonial.**
