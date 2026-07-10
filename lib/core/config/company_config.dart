import 'package:flutter/material.dart';

class CompanyConfig {
  final String name;
  final String code;
  final String pilarKey;
  final Color primaryColor;
  final String pdfTitle;
  final String legalTerms;
  final String tagline;
  final List<String> bankAccounts;

  const CompanyConfig({
    required this.name,
    required this.code,
    required this.pilarKey,
    required this.primaryColor,
    required this.pdfTitle,
    required this.legalTerms,
    required this.tagline,
    required this.bankAccounts,
  });

  static const List<CompanyConfig> allConfigs = [
    CompanyConfig(
      name: 'KST Software & Plataformas',
      code: 'SW',
      pilarKey: 'C',
      primaryColor: Color(0xFF3F51B5), // Indigo/Royal Blue
      pdfTitle: 'PROPUESTA COMERCIAL - DESARROLLO DE SOFTWARE',
      legalTerms: 'La presente propuesta incluye el desarrollo y licenciamiento según el alcance establecido. Se otorga una garantía de 90 días naturales posteriores a la entrega para la corrección de errores de código sin costo adicional.',
      tagline: '“La clave que impulsa tus soluciones tecnológicas”',
      bankAccounts: [
        'KST Software BBVA: 0122 3456 7890 Clabe: 0123 4567 8901 2345 67',
      ],
    ),
    CompanyConfig(
      name: 'KST Infraestructura & Redes',
      code: 'IN',
      pilarKey: 'A',
      primaryColor: Color(0xFF00ACC1), // Cyan/Teal
      pdfTitle: 'PROPUESTA COMERCIAL - INFRAESTRUCTURA Y REDES',
      legalTerms: 'Sujeto a existencias y variación de precios de proveedores. Los equipos cuentan con la garantía de fabricante aplicable. La instalación física cuenta con 90 días de garantía en mano de obra.',
      tagline: '“Conectividad y robustez para tu infraestructura”',
      bankAccounts: [
        'KST Infraestructura BBVA: 0122 9876 5432 Clabe: 0123 9876 5432 1098 76',
      ],
    ),
    CompanyConfig(
      name: 'KST Soporte & Mantenimiento',
      code: 'SP',
      pilarKey: 'B',
      primaryColor: Color(0xFFF57C00), // Orange/Amber
      pdfTitle: 'PROPUESTA COMERCIAL - SOPORTE Y MANTENIMIENTO',
      legalTerms: 'Los servicios de soporte técnico se brindan bajo modalidad de póliza o evento único. Las horas de servicio excedentes se facturarán por separado de acuerdo con la tarifa establecida.',
      tagline: '“Soporte experto para la continuidad de tu negocio”',
      bankAccounts: [
        'KST Soporte BBVA: 0122 5555 4444 Clabe: 0123 5555 4444 3333 22',
      ],
    ),
    CompanyConfig(
      name: 'KST Media & Servicios Creativos',
      code: 'MC',
      pilarKey: 'E',
      primaryColor: Color(0xFF4CAF50), // Green/Emerald
      pdfTitle: 'PROPUESTA COMERCIAL - SERVICIOS CREATIVOS Y MEDIA',
      legalTerms: 'El entregable creativo (videos, diseños, animaciones) se entrega con derechos de uso comercial para el cliente. Incluye hasta 2 rondas de revisiones sobre el producto entregable.',
      tagline: '“Creatividad y diseño que potencian tu marca”',
      bankAccounts: [
        'KST Creativos BBVA: 0122 7777 8888 Clabe: 0123 7777 8888 9999 00',
      ],
    ),
    CompanyConfig(
      name: 'KST Finanzas & Pagos',
      code: 'FP',
      pilarKey: 'D',
      primaryColor: Color(0xFFE91E63), // Pink/Magenta
      pdfTitle: 'PROPUESTA COMERCIAL - FINANZAS Y PAGOS',
      legalTerms: 'Los servicios financieros y de procesamiento de pagos se rigen por las comisiones y términos acordados en la solicitud de servicio correspondiente.',
      tagline: '“Agilidad y seguridad en tus transacciones”',
      bankAccounts: [
        'KST Finanzas BBVA: 0122 1111 2222 Clabe: 0123 1111 2222 3333 44',
      ],
    ),
  ];

  static CompanyConfig fromPilarKey(String? key) {
    if (key == null) return allConfigs.first;
    return allConfigs.firstWhere(
      (c) => c.pilarKey == key,
      orElse: () => allConfigs.first,
    );
  }

  static CompanyConfig fromName(String? name) {
    if (name == null || name.isEmpty) return allConfigs.first;
    final normalized = name.trim().toLowerCase();
    return allConfigs.firstWhere(
      (c) => c.name.toLowerCase().contains(normalized) || normalized.contains(c.name.toLowerCase()),
      orElse: () => allConfigs.first,
    );
  }
}
