// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'KST Business';
  static const String companyName = 'Key Solutions Technology';
  static const String companyTagline = 'Cotizador Inteligente';

  // Supabase – replace with your actual project values
  static const String supabaseUrl = 'https://ozcknultatuiybmcarog.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_jJJQkpeEhyLW-CZk71Xnsg_W-VzHc6N';

  // Urgency multipliers
  static const double urgencyStandard = 1.0;
  static const double urgencyExpress = 1.25;
  static const double urgencyImmediate = 1.5;
  static const double urgencyEmergency = 2.0;

  // Micro-transaction commission (MXN)
  static const double microTransactionCommission = 5.0;

  // Quote validity options (days)
  static const List<int> validityDays = [7, 15, 30];

  // Billing types (tipo_cobro)
  static const String tipoCobroFijoPrecio = 'FIJO_PRECIO';
  static const String tipoCobroCostoMarkup = 'COSTO_MARKUP';
  static const String tipoCobroTarifaBaseExtras = 'TARIFA_BASE_EXTRAS';
  static const String tipoCobroPorHoraModulo = 'POR_HORA_MODULO';
  static const String tipoCobroMontoMasComision = 'MONTO_MAS_COMISION';
  static const String tipoCobroHibridoCreativo = 'HIBRIDO_CREATIVO';

  // Roles
  static const String roleAdmin = 'administrador';
  static const String roleVendedor = 'vendedor';

  // PDF
  static const String pdfCompanyEmail = 'contacto@keysolutions.mx';
  static const String pdfCompanyPhone = '+52 (XXX) XXX-XXXX';
  static const String pdfCompanyWebsite = 'www.keysolutions.mx';
}
