const functions = require('firebase-functions');
const admin = require('firebase-admin');
const PdfPrinter = require('pdfmake');

admin.initializeApp();
const db = admin.firestore();

// FUENTES: pdfmake requiere archivos de fuente. 
// En producción, estos deben estar en una carpeta 'fonts' dentro de functions.
const fonts = {
  Roboto: {
    normal: 'Helvetica', // Usamos fuentes estándar de PDF como fallback si no hay archivos .ttf
    bold: 'Helvetica-Bold',
    italics: 'Helvetica-Oblique',
    bolditalics: 'Helvetica-BoldOblique'
  }
};

/**
 * Función para generar reportes oficiales en PDF
 * Recibe: { area: "Nombre del Area", secretaria: "Nombre Secretaria" }
 */
exports.generarReporteInventario = functions.https.onCall(async (data, context) => {
  // 1. Verificación de Autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'El usuario debe estar autenticado.');
  }

  try {
    const areaSolicitada = data.area;

    // 2. Obtener datos de Firestore
    // Filtramos los bienes por el área proporcionada
    const snapshot = await db.collection('bienes')
      .where('ubicacion_actual.area', '==', areaSolicitada)
      .get();

    if (snapshot.empty) {
      return { error: 'No se encontraron bienes para esta área.' };
    }

    const listaBienes = snapshot.docs.map(doc => ({
      id: doc.data().id_bien || doc.id,
      descripcion: doc.data().nombre_bien || 'Sin descripción',
      estatus: doc.data().estatus_verificacion || 'PENDIENTE',
      serie: doc.data().serie || 'N/A'
    }));

    // 3. Definir estructura del PDF (Estilo Institucional)
    const docDefinition = {
      header: {
        margin: [40, 20, 40, 0],
        columns: [
          {
            text: 'GOBIERNO DEL ESTADO DE MÉXICO',
            style: 'headerTop',
            alignment: 'left'
          },
          {
            text: 'SICOPA - SISTEMA DE CONTROL',
            style: 'headerTop',
            alignment: 'right'
          }
        ]
      },
      footer: (currentPage, pageCount) => {
        return {
          text: `Página ${currentPage} de ${pageCount}`,
          alignment: 'center',
          style: 'footerText'
        };
      },
      content: [
        { text: '\n\nREPORTE DE VERIFICACIÓN DE INVENTARIO', style: 'mainTitle' },
        { text: `ÁREA: ${areaSolicitada}`, style: 'subTitle' },
        { text: `FECHA DE GENERACIÓN: ${new Date().toLocaleString()}`, style: 'dateStyle' },
        { text: '\n' },
        {
          table: {
            headerRows: 1,
            widths: ['20%', '45%', '15%', '20%'],
            body: [
              // Cabecera de la tabla con color institucional (Rojo)
              [
                { text: 'ID BIEN', style: 'tableHeader' },
                { text: 'DESCRIPCIÓN', style: 'tableHeader' },
                { text: 'ESTATUS', style: 'tableHeader' },
                { text: 'SERIE', style: 'tableHeader' }
              ],
              // Filas de datos
              ...listaBienes.map(b => [
                { text: b.id, style: 'tableCell' },
                { text: b.descripcion, style: 'tableCell' },
                {
                  text: b.estatus,
                  style: 'tableCell',
                  color: b.estatus === 'UBICADO' ? '#27ae60' : '#c0392b',
                  bold: true
                },
                { text: b.serie, style: 'tableCell' }
              ])
            ]
          },
          layout: 'lightHorizontalLines'
        },
        { text: '\n\n\n__________________________', alignment: 'center' },
        { text: 'Firma del Resguardatario', alignment: 'center', style: 'signature' }
      ],
      styles: {
        headerTop: { fontSize: 9, color: '#A62145', bold: true },
        mainTitle: { fontSize: 18, bold: true, alignment: 'center', color: '#333' },
        subTitle: { fontSize: 14, alignment: 'center', margin: [0, 5, 0, 10] },
        dateStyle: { fontSize: 10, alignment: 'right', italic: true },
        tableHeader: {
          fillColor: '#A62145',
          color: 'white',
          bold: true,
          alignment: 'center',
          fontSize: 10,
          margin: [0, 5, 0, 5]
        },
        tableCell: { fontSize: 9, margin: [0, 3, 0, 3] },
        signature: { fontSize: 10, italic: true },
        footerText: { fontSize: 8, color: '#666' }
      }
    };

    // 4. Generar el PDF y convertirlo a Base64
    const printer = new PdfPrinter(fonts);
    const pdfDoc = printer.createPdfKitDocument(docDefinition);

    return new Promise((resolve, reject) => {
      let chunks = [];
      pdfDoc.on('data', (chunk) => chunks.push(chunk));
      pdfDoc.on('end', () => {
        const result = Buffer.concat(chunks);
        resolve({
          pdfBase64: result.toString('base64'),
          fileName: `Reporte_${areaSolicitada.replace(/\s+/g, '_')}.pdf`
        });
      });
      pdfDoc.on('error', (err) => {
        reject(new functions.https.HttpsError('internal', 'Error al generar PDF: ' + err.message));
      });
      pdfDoc.end();
    });

  } catch (error) {
    console.error('Error en generarReporteInventario:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Función para cargar bienes de forma masiva
 * Recibe: { bienes: [ { id_bien, nombre_bien, ... }, ... ] }
 */
exports.cargaMasivaBienes = functions.https.onCall(async (data, context) => {
  // Solo administradores supremos pueden usar esta función
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'No autenticado.');

  const userRef = db.collection('usuarios').doc(context.auth.uid);
  const userDoc = await userRef.get();
  if (userDoc.data().rol !== 'ADMIN_SUPREMO') {
    throw new functions.https.HttpsError('permission-denied', 'Solo el Administrador Supremo puede realizar cargas masivas.');
  }

  const bienes = data.bienes;
  if (!Array.isArray(bienes)) throw new functions.https.HttpsError('invalid-argument', 'Se esperaba un array de bienes.');

  const collectionRef = db.collection('bienes');
  let count = 0;

  // Procesar en lotes de 500 (límite de Firestore WriteBatch)
  for (let i = 0; i < bienes.length; i += 500) {
    const batch = db.batch();
    const chunk = bienes.slice(i, i + 500);

    chunk.forEach(bien => {
      // Usamos el id_bien como ID del documento para evitar duplicados
      const docRef = collectionRef.doc(bien.id_bien.toString());
      batch.set(docRef, {
        ...bien,
        ultima_actualizacion: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      count++;
    });

    await batch.commit();
  }

  return { success: true, processedBienes: count };
});

