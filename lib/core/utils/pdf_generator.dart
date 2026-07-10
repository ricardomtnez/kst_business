// lib/core/utils/pdf_generator.dart
// Generates branded PDF matching PROPUESTA COMERCIAL.pdf

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:kst_business/features/quotes/models/quote.dart';
import 'package:kst_business/core/config/company_config.dart';
import '../constants/app_constants.dart';

class PdfGenerator {
  static final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  static final _textPrimary = PdfColor.fromHex('#0F172A');
  static final _textSecondary = PdfColor.fromHex('#475569');
  static final _borderGrey = PdfColor.fromHex('#E2E8F0');

  static Future<Uint8List> generate(Quote quote) async {
    final doc = pw.Document();

    // Determine CompanyConfig based on the first item's business pillar
    final firstItemPilar = quote.items.isNotEmpty ? quote.items.first.catalogItem.pilar.key : 'C';
    final config = CompanyConfig.fromPilarKey(firstItemPilar);
    final brandColor = PdfColor.fromInt(config.primaryColor.toARGB32());

    // 1. Try to load KST logo and wolf icon from assets
    pw.MemoryImage? logoImage;
    pw.MemoryImage? iconoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    try {
      final iconoData = await rootBundle.load('assets/images/icono.png');
      iconoImage = pw.MemoryImage(iconoData.buffer.asUint8List());
    } catch (_) {}

    // Get dynamic salesperson details from Supabase auth
    final user = Supabase.instance.client.auth.currentUser;
    final sellerEmail = user?.email ?? 'contacto@keysolutions.mx';
    final sellerName = user?.userMetadata?['full_name'] as String? ?? 'ING. EZEQUIEL VELEZ ESPINOZA';
    final sellerPhone = user?.userMetadata?['phone'] as String? ?? '247 107 2139';

    // Page 1: Commercial Proposal details & Deliverables list
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 45),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(quote, logoImage, 1, 2, brandColor),
              pw.SizedBox(height: 24),

              // Title
              pw.Text(
                config.pdfTitle,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: brandColor,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 20),

              // Client details block
              _buildInfoRow('Atención:', quote.cliente.nombre + (quote.cliente.empresa != null ? ' - ${quote.cliente.empresa}' : ''), brandColor),
              _buildInfoRow('Entregable:', quote.items.map((i) => i.catalogItem.nombre).join(', '), brandColor),
              _buildInfoRow('Inversión:', '${_fmt.format(quote.total)} MXN', brandColor),
              _buildInfoRow('Tiempo estimado:', quote.notas != null && quote.notas!.contains('semana') 
                  ? _extractWeeks(quote.notas!) 
                  : '4 a 6 semanas', brandColor),
              pw.SizedBox(height: 20),

              // Propuesta de valor
              pw.Text(
                'Propuesta de valor:',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Diseño y desarrollo de una solución tecnológica orientada a crear la presencia digital de la empresa, comunicar de manera efectiva su propuesta de valor y consolidar una imagen profesional que genere confianza en clientes, socios comerciales e inversionistas. La solución contempla una experiencia visual moderna y alineada con la identidad corporativa de la organización, incorporando herramientas que faciliten el contacto con clientes potenciales y respalden el crecimiento del negocio.',
                style: pw.TextStyle(fontSize: 10, color: _textSecondary, height: 1.4),
              ),
              pw.SizedBox(height: 20),

              // Deliverables list
              pw.Text(
                'Entregables:',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor),
              ),
              pw.SizedBox(height: 8),
              pw.Expanded(
                child: pw.ListView.builder(
                  itemCount: quote.items.length,
                  itemBuilder: (ctx, i) {
                    final item = quote.items[i];
                    String title = item.catalogItem.nombre;
                    String description = item.catalogItem.descripcion;
                    bool isCustomMod = item.isPorPuntos || item.isPorMinutos;

                    if (item.isPorPuntos) {
                      final totalPoints = item.requisitos?.fold<int>(0, (s, r) => s + r.puntos) ?? 0;
                      title = '$title ($totalPoints Puntos de Historia)';
                      final rateStr = _fmt.format(item.tarifaPunto ?? 1000);
                      final reqsList = item.requisitos != null
                          ? item.requisitos!.map((r) => '    • ${r.descripcion} (${r.puntos} pts)').join('\n')
                          : '    • Sin requerimientos detallados';
                      description = 'Cotización a medida basada en Matriz de Complejidad y Riesgos.\nTarifa: $rateStr por Punto de Historia.\nRequerimientos:\n$reqsList';
                    } else if (item.isPorMinutos) {
                      final dur = item.duracionMinutos?.toStringAsFixed(1) ?? '0.0';
                      title = '$title ($dur minutos de duración)';
                      final rateStr = _fmt.format(item.tarifaMinuto ?? 1500);
                      description = 'Cotizado por duración de video. Tarifa de $rateStr/minuto.';
                    } else {
                      final String notes = item.notas ?? '';
                      if (notes.contains('||')) {
                        final parts = notes.split('||');
                        title = parts[0].trim();
                        description = parts[1].trim();
                      } else if (notes.isNotEmpty) {
                        description = notes;
                      }
                    }

                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ', style: pw.TextStyle(fontSize: 11, color: brandColor, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                style: pw.TextStyle(fontSize: 10, color: _textSecondary, height: 1.35),
                                children: [
                                  if (isCustomMod) ...[
                                    pw.TextSpan(
                                      text: '$title:\n',
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _textPrimary),
                                    ),
                                    pw.TextSpan(text: description),
                                  ] else ...[
                                    pw.TextSpan(
                                      text: '$title (${item.cantidad.toStringAsFixed(0)} ${item.catalogItem.unidad ?? "pza"}): ',
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _textPrimary),
                                    ),
                                    pw.TextSpan(text: description),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Footer
              _buildFooter(iconoImage, brandColor, config),
            ],
          );
        },
      ),
    );

    // Page 2: Terms, considerations, warranty, and signature
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 45),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(quote, logoImage, 2, 2, brandColor),
              pw.SizedBox(height: 24),

              // Payment terms
              pw.Text(
                'CONDICIONES DE PAGO',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor),
              ),
              pw.SizedBox(height: 8),
              _buildBulletItem('El precio es NETO.', brandColor),
              _buildBulletItem('De Contado (50% de anticipo y el resto contra entrega del producto/servicio).', brandColor),
              if (config.bankAccounts.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _buildBulletItem('Depósito o Transferencia en las siguientes cuentas:\n${config.bankAccounts.map((b) => '    • $b').join('\n')}', brandColor),
              ],
              pw.SizedBox(height: 20),

              // General considerations
              pw.Text(
                'CONSIDERACIONES GENERALES',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'La presente propuesta incluye únicamente los servicios y productos descritos en este documento. No incluye:',
                style: pw.TextStyle(fontSize: 10, color: _textSecondary),
              ),
              pw.SizedBox(height: 8),
              _buildBulletItem('Compra de hosting (Si se contrata con nosotros, se ofrece un precio especial de \$1,000.00 MXN el primer año).', brandColor),
              _buildBulletItem('Compra de dominio (Precio variable según extensión y nombre).', brandColor),
              _buildBulletItem('Licencias de software o APIs de terceros.', brandColor),
              _buildBulletItem('Cualquier requerimiento adicional no descrito en la sección de entregables, el cual podrá cotizarse por separado mediante una orden de cambio.', brandColor),
              pw.SizedBox(height: 20),

              // Warranty
              pw.Text(
                'GARANTÍA Y TÉRMINOS LEGALES',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                config.legalTerms,
                style: pw.TextStyle(fontSize: 10, color: _textSecondary, height: 1.3),
              ),
              pw.SizedBox(height: 40),

              // Sign-off
              pw.Text(
                'A T E N T A M E N T E',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brandColor, letterSpacing: 2),
              ),
              pw.SizedBox(height: 32),

              pw.Column(
                children: [
                  pw.Text(
                    sellerName.toUpperCase(),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _textPrimary),
                  ),
                  pw.Text(
                    'CONSULTOR DE SOLUCIONES TECNOLÓGICAS',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal, color: brandColor, letterSpacing: 0.5),
                  ),
                  pw.Text(
                    'Tel: $sellerPhone',
                    style: pw.TextStyle(fontSize: 9, color: _textSecondary),
                  ),
                  pw.Text(
                    'Correo: $sellerEmail',
                    style: pw.TextStyle(fontSize: 9, color: _textSecondary),
                  ),
                ],
              ),
              
              pw.Spacer(),

              // Footer
              _buildFooter(iconoImage, brandColor, config),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ─── Header Widget ──────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(Quote quote, pw.MemoryImage? logo, int pageNum, int totalPages, PdfColor brandColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: brandColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Logo on the left
          pw.Container(
            height: 48,
            child: logo != null
                ? pw.Image(logo, fit: pw.BoxFit.contain)
                : pw.Text(
                    'KEY SOLUTIONS\nTECHNOLOGY',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor),
                  ),
          ),
          
          // Metadata on the right
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'COTIZACIÓN',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: brandColor, letterSpacing: 1),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Página $pageNum-$totalPages',
                style: pw.TextStyle(fontSize: 9, color: _textSecondary),
              ),
              pw.Text(
                quote.numero,
                style: pw.TextStyle(fontSize: 10, color: brandColor, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Fecha: ${_dateFmt.format(quote.creadoEn)}',
                style: pw.TextStyle(fontSize: 9, color: _textSecondary),
              ),
              pw.Text(
                'Vigencia: ${_dateFmt.format(quote.fechaVencimiento)}',
                style: pw.TextStyle(fontSize: 9, color: _textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Footer Widget ──────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.MemoryImage? icon, PdfColor brandColor, CompanyConfig config) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderGrey, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (icon != null) ...[
                pw.Container(
                  height: 16,
                  child: pw.Image(icon, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 8),
              ],
              pw.Container(
                width: 1,
                height: 14,
                color: _textSecondary,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                AppConstants.pdfCompanyWebsite,
                style: pw.TextStyle(fontSize: 9, color: brandColor, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.Text(
            config.tagline,
            style: pw.TextStyle(fontSize: 9, color: _textSecondary, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static pw.Widget _buildInfoRow(String label, String value, PdfColor brandColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brandColor),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, color: _textPrimary, fontWeight: pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletItem(String text, PdfColor brandColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(fontSize: 11, color: brandColor, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 10, color: _textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  static String _extractWeeks(String notes) {
    final match = RegExp(r'(\d+)\s*a\s*(\d+)\s*semanas').firstMatch(notes);
    if (match != null) {
      return '${match.group(1)} a ${match.group(2)} semanas';
    }
    return '4 a 6 semanas';
  }
}
