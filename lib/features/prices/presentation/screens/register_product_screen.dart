// lib/features/prices/presentation/screens/register_product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/prices/models/catalog_item.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:intl/intl.dart';

class RegisterProductScreen extends ConsumerStatefulWidget {
  const RegisterProductScreen({super.key, this.editItem});

  final CatalogItem? editItem;

  @override
  ConsumerState<RegisterProductScreen> createState() => _RegisterProductScreenState();
}

class _RegisterProductScreenState extends ConsumerState<RegisterProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // General fields
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _categoryCtrl;

  // Pilar A fields
  late final TextEditingController _costoCtrl;
  late final TextEditingController _margenCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _garantiaCtrl;
  late final TextEditingController _dimensionesCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _stockCtrl;
  late bool _esRezago;

  // Pilar B fields
  late final TextEditingController _tarifaHoraExtraCtrl;
  late final TextEditingController _duracionEstimadaCtrl;
  String _modalidadServicio = 'remoto'; // remoto, presencial, hibrido
  bool _incluyeVisita = false;

  // Pilar C fields
  late final TextEditingController _horasEstimadasCtrl;
  late final TextEditingController _garantiaEntregaCtrl;
  String _tipoProyecto = 'web'; // web, movil, desktop, api, automatizacion, erp, otro
  final List<String> _tecnologias = [];
  final List<Map<String, dynamic>> _modulos = [];
  final _techInputCtrl = TextEditingController();

  // Pilar C dynamic module form inputs
  final _modNombreCtrl = TextEditingController();
  final _modDescCtrl = TextEditingController();
  final _modHorasCtrl = TextEditingController();
  final _modPrecioCtrl = TextEditingController();

  // Pilar D fields
  late final TextEditingController _comisionFijaCtrl;
  late final TextEditingController _comisionPorcentajeCtrl;
  late final TextEditingController _montoMinimoCtrl;
  late final TextEditingController _montoMaximoCtrl;
  String _tipoPago = 'cfe'; // cfe, agua, telefono, recarga, transferencia, predial, seguro, otro

  // Pilar E fields
  late final TextEditingController _revisionesCtrl;
  late final TextEditingController _tiempoEntregaCtrl;
  late final TextEditingController _formatoSalidaCtrl;
  late final TextEditingController _tarifaHoraCreativaCtrl;
  String _tipoContenido = 'video'; // video, diseno, fotografia, animacion, audio, branding, otro
  final List<String> _entregables = [];
  final _entregableInputCtrl = TextEditingController();

  // Image Gallery
  final List<String> _imagenesUrls = [];
  final _imageUrlInputCtrl = TextEditingController();

  // Custom Characteristics (Common Extra)
  final List<Map<String, dynamic>> _caracteristicas = [];
  final _charKeyCtrl = TextEditingController();
  final _charValueCtrl = TextEditingController();

  late PilarNegocio _selectedPilar;
  late TipoCobro _selectedTipo;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  // New Calculator Variables
  late final TextEditingController _tarifaBaseCtrl;
  late final TextEditingController _viaticosCtrl;
  late final TextEditingController _tarifaHoraCtrl;
  bool _pilarCUseStoryPoints = false;
  int? _pilarCSelectedPuntos;
  late final TextEditingController _pilarCTarifaPuntoCtrl;
  late final TextEditingController _tarifaBasePaqueteCtrl;
  late final TextEditingController _horasCreativasCtrl;
  
  late final TextEditingController _pilarETarifaHoraCtrl;
  late final TextEditingController _pilarEHorasEstimadasCtrl;
  late final TextEditingController _pilarETarifaMinutoCtrl;
  late final TextEditingController _pilarEMinutosCtrl;
  String _pilarECobroScheme = 'paquete'; // paquete, horas, minutos

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;

    // General controllers
    _nameCtrl = TextEditingController(text: item?.nombre ?? '');
    _descCtrl = TextEditingController(text: item?.descripcion ?? '');
    _priceCtrl = TextEditingController(text: item != null ? item.precioBase.toStringAsFixed(2) : '');
    _unitCtrl = TextEditingController(text: item?.unidad ?? 'pza');
    _categoryCtrl = TextEditingController(text: item?.categoria ?? '');

    // Pilar A
    _costoCtrl = TextEditingController(text: item?.costoProveedor?.toStringAsFixed(2) ?? '');
    _margenCtrl = TextEditingController(text: item?.margenPorcentaje?.toStringAsFixed(0) ?? '');
    _marcaCtrl = TextEditingController(text: item?.marca ?? '');
    _modeloCtrl = TextEditingController(text: item?.modelo ?? '');
    _garantiaCtrl = TextEditingController(text: item?.garantia ?? '');
    _dimensionesCtrl = TextEditingController(text: item?.dimensiones ?? '');
    _pesoCtrl = TextEditingController(text: item?.pesoKg?.toStringAsFixed(2) ?? '');
    _stockCtrl = TextEditingController(text: item?.stock?.toStringAsFixed(0) ?? '0');
    _esRezago = item?.esRezago ?? false;

    // Pilar B
    _tarifaHoraExtraCtrl = TextEditingController(text: item?.tarifaHoraExtra?.toStringAsFixed(2) ?? '');
    _duracionEstimadaCtrl = TextEditingController(text: item?.duracionEstimada ?? '');
    _modalidadServicio = item?.modalidadServicio ?? 'remoto';
    _incluyeVisita = item?.incluyeVisita ?? false;
    _tarifaBaseCtrl = TextEditingController(text: item != null && item.pilar == PilarNegocio.serviciosTecnicos ? item.precioBase.toStringAsFixed(2) : '');
    _viaticosCtrl = TextEditingController(text: '');

    // Pilar C
    _horasEstimadasCtrl = TextEditingController(text: item?.horasEstimadas?.toStringAsFixed(1) ?? '');
    _garantiaEntregaCtrl = TextEditingController(text: item?.garantiaEntrega ?? '');
    _tipoProyecto = item?.tipoProyecto ?? 'web';
    _pilarCUseStoryPoints = item?.isPorPuntos ?? false;
    _pilarCSelectedPuntos = item?.puntos;
    _pilarCTarifaPuntoCtrl = TextEditingController(text: item?.tarifaPunto?.toStringAsFixed(2) ?? '2000.00');
    _tarifaHoraCtrl = TextEditingController(text: item != null && item.pilar == PilarNegocio.proyectosComplexos && !item.isPorPuntos ? item.precioBase.toStringAsFixed(2) : '800.00');
    if (item?.tecnologias != null) {
      _tecnologias.addAll(item!.tecnologias);
    }
    if (item?.modulos != null) {
      _modulos.addAll(item!.modulos);
    }

    // Pilar D
    _comisionFijaCtrl = TextEditingController(text: item?.comisionFija?.toStringAsFixed(2) ?? '');
    _comisionPorcentajeCtrl = TextEditingController(text: item?.comisionPorcentaje?.toStringAsFixed(2) ?? '');
    _montoMinimoCtrl = TextEditingController(text: item?.montoMinimo?.toStringAsFixed(2) ?? '');
    _montoMaximoCtrl = TextEditingController(text: item?.montoMaximo?.toStringAsFixed(2) ?? '');
    _tipoPago = item?.tipoPago ?? 'cfe';

    // Pilar E
    final pilarUnit = item?.unidad?.toLowerCase() ?? 'pza';
    if (pilarUnit == 'min' || pilarUnit == 'minuto') {
      _pilarECobroScheme = 'minutos';
    } else if (pilarUnit == 'hr' || pilarUnit == 'hora') {
      _pilarECobroScheme = 'horas';
    } else {
      _pilarECobroScheme = 'paquete';
    }

    _revisionesCtrl = TextEditingController(text: item?.revisionesIncluidas?.toString() ?? '2');
    _tiempoEntregaCtrl = TextEditingController(text: item?.tiempoEntrega ?? '');
    _formatoSalidaCtrl = TextEditingController(text: item?.formatoSalida ?? '');
    _tarifaHoraCreativaCtrl = TextEditingController(text: item?.tarifaHoraCreativa?.toStringAsFixed(2) ?? '');
    _tipoContenido = item?.tipoContenido ?? 'video';
    _tarifaBasePaqueteCtrl = TextEditingController(
      text: item != null && item.pilar == PilarNegocio.serviciosCreativos && _pilarECobroScheme == 'paquete' 
            ? item.precioBase.toStringAsFixed(2) : '3000.00',
    );
    _horasCreativasCtrl = TextEditingController(text: '0');

    _pilarETarifaHoraCtrl = TextEditingController(
      text: item != null && item.pilar == PilarNegocio.serviciosCreativos && _pilarECobroScheme == 'horas'
            ? item.precioBase.toStringAsFixed(2) : '500.00',
    );
    _pilarEHorasEstimadasCtrl = TextEditingController(
      text: item != null && item.pilar == PilarNegocio.serviciosCreativos && _pilarECobroScheme == 'horas'
            ? (item.horasEstimadas ?? 10.0).toStringAsFixed(1) : '10.0',
    );
    _pilarETarifaMinutoCtrl = TextEditingController(
      text: item != null && item.pilar == PilarNegocio.serviciosCreativos && _pilarECobroScheme == 'minutos'
            ? item.precioBase.toStringAsFixed(2) : '1000.00',
    );
    _pilarEMinutosCtrl = TextEditingController(
      text: item != null && item.pilar == PilarNegocio.serviciosCreativos && _pilarECobroScheme == 'minutos'
            ? (item.horasEstimadas ?? 3.0).toStringAsFixed(1) : '3.0',
    );

    if (item?.entregables != null) {
      _entregables.addAll(item!.entregables);
    }

    // Common gallery & characteristics
    if (item?.imagenesUrls != null) {
      _imagenesUrls.addAll(item!.imagenesUrls);
    } else if (item?.imagenUrl != null && item!.imagenUrl!.isNotEmpty) {
      _imagenesUrls.add(item.imagenUrl!);
    }
    if (item?.caracteristicas != null) {
      _caracteristicas.addAll(item!.caracteristicas);
    }

    _selectedPilar = item?.pilar ?? PilarNegocio.productosInventario;
    _selectedTipo = item?.tipoCobro ?? TipoCobro.costoMarkup;

    _recalculatePrice();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    _categoryCtrl.dispose();
    _costoCtrl.dispose();
    _margenCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _garantiaCtrl.dispose();
    _dimensionesCtrl.dispose();
    _pesoCtrl.dispose();
    _stockCtrl.dispose();
    _tarifaHoraExtraCtrl.dispose();
    _duracionEstimadaCtrl.dispose();
    _horasEstimadasCtrl.dispose();
    _garantiaEntregaCtrl.dispose();
    _techInputCtrl.dispose();
    _modNombreCtrl.dispose();
    _modDescCtrl.dispose();
    _modHorasCtrl.dispose();
    _modPrecioCtrl.dispose();
    _comisionFijaCtrl.dispose();
    _comisionPorcentajeCtrl.dispose();
    _montoMinimoCtrl.dispose();
    _montoMaximoCtrl.dispose();
    _revisionesCtrl.dispose();
    _tiempoEntregaCtrl.dispose();
    _formatoSalidaCtrl.dispose();
    _tarifaHoraCreativaCtrl.dispose();
    _entregableInputCtrl.dispose();
    _imageUrlInputCtrl.dispose();
    _charKeyCtrl.dispose();
    _charValueCtrl.dispose();

    _tarifaBaseCtrl.dispose();
    _viaticosCtrl.dispose();
    _tarifaHoraCtrl.dispose();
    _pilarCTarifaPuntoCtrl.dispose();
    _tarifaBasePaqueteCtrl.dispose();
    _horasCreativasCtrl.dispose();
    
    _pilarETarifaHoraCtrl.dispose();
    _pilarEHorasEstimadasCtrl.dispose();
    _pilarETarifaMinutoCtrl.dispose();
    _pilarEMinutosCtrl.dispose();

    super.dispose();
  }

  void _onPilarSelected(PilarNegocio pilar) {
    setState(() {
      _selectedPilar = pilar;
      // Auto-assign TipoCobro based on selected pilar
      switch (pilar) {
        case PilarNegocio.productosInventario:
          _selectedTipo = TipoCobro.costoMarkup;
          _unitCtrl.text = 'pza';
          break;
        case PilarNegocio.serviciosTecnicos:
          _selectedTipo = TipoCobro.tarifaBaseExtras;
          _unitCtrl.text = 'servicio';
          break;
        case PilarNegocio.proyectosComplexos:
          _selectedTipo = TipoCobro.porHoraModulo;
          _unitCtrl.text = 'proyecto';
          break;
        case PilarNegocio.microTransacciones:
          _selectedTipo = TipoCobro.montoMasComision;
          _unitCtrl.text = 'transacción';
          break;
        case PilarNegocio.serviciosCreativos:
          _selectedTipo = TipoCobro.hibridoCreativo;
          _unitCtrl.text = 'entregable';
          break;
      }
    });
  }

  void _recalculatePrice() {
    setState(() {
      switch (_selectedPilar) {
        case PilarNegocio.productosInventario:
          final costo = double.tryParse(_costoCtrl.text) ?? 0.0;
          final margen = double.tryParse(_margenCtrl.text) ?? 0.0;
          if (costo > 0) {
            final calculated = costo * (1 + margen / 100);
            _priceCtrl.text = calculated.toStringAsFixed(2);
          }
          break;

        case PilarNegocio.serviciosTecnicos:
          final tarifaBase = double.tryParse(_tarifaBaseCtrl.text) ?? 0.0;
          final viaticos = double.tryParse(_viaticosCtrl.text) ?? 0.0;
          final total = tarifaBase + viaticos;
          _priceCtrl.text = total.toStringAsFixed(2);
          break;

        case PilarNegocio.proyectosComplexos:
          if (_pilarCUseStoryPoints) {
            final puntos = _pilarCSelectedPuntos ?? 0;
            final tarifaPunto = double.tryParse(_pilarCTarifaPuntoCtrl.text) ?? 0.0;
            final total = puntos * tarifaPunto;
            _priceCtrl.text = total.toStringAsFixed(2);
          } else {
            final tarifaHora = double.tryParse(_tarifaHoraCtrl.text) ?? 0.0;
            final horas = double.tryParse(_horasEstimadasCtrl.text) ?? 0.0;
            double modulosSum = 0.0;
            for (final mod in _modulos) {
              modulosSum += (mod['precio'] as num).toDouble();
            }
            final total = (tarifaHora * horas) + modulosSum;
            _priceCtrl.text = total.toStringAsFixed(2);
          }
          break;

        case PilarNegocio.microTransacciones:
          final fija = double.tryParse(_comisionFijaCtrl.text) ?? 0.0;
          _priceCtrl.text = fija.toStringAsFixed(2);
          break;

        case PilarNegocio.serviciosCreativos:
          if (_pilarECobroScheme == 'paquete') {
            final base = double.tryParse(_tarifaBasePaqueteCtrl.text) ?? 0.0;
            _priceCtrl.text = base.toStringAsFixed(2);
            _unitCtrl.text = 'entregable';
          } else if (_pilarECobroScheme == 'horas') {
            final tarifaHora = double.tryParse(_pilarETarifaHoraCtrl.text) ?? 0.0;
            final horas = double.tryParse(_pilarEHorasEstimadasCtrl.text) ?? 0.0;
            final total = tarifaHora * horas;
            _priceCtrl.text = total.toStringAsFixed(2);
            _unitCtrl.text = 'hr';
          } else {
            final tarifaMinuto = double.tryParse(_pilarETarifaMinutoCtrl.text) ?? 0.0;
            final minutos = double.tryParse(_pilarEMinutosCtrl.text) ?? 0.0;
            final total = tarifaMinuto * minutos;
            _priceCtrl.text = total.toStringAsFixed(2);
            _unitCtrl.text = 'min';
          }
          break;
      }
    });
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (_imagenesUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Límite máximo de 5 imágenes alcanzado.')),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await pickedFile.readAsBytes();
      final fileName = 'cat_${const Uuid().v4()}.jpg';

      final supabase = Supabase.instance.client;
      await supabase.storage.from('catalog').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
      );

      final publicUrl = supabase.storage.from('catalog').getPublicUrl(fileName);

      setState(() {
        _imagenesUrls.add(publicUrl);
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen agregada a la galería ✓')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al subir imagen: $e')),
        );
      }
    }
  }

  void _addTechChip() {
    final tech = _techInputCtrl.text.trim();
    if (tech.isNotEmpty && !_tecnologias.contains(tech)) {
      setState(() {
        _tecnologias.add(tech);
        _techInputCtrl.clear();
      });
    }
  }

  void _addEntregable() {
    final ent = _entregableInputCtrl.text.trim();
    if (ent.isNotEmpty && !_entregables.contains(ent)) {
      setState(() {
        _entregables.add(ent);
        _entregableInputCtrl.clear();
      });
    }
  }

  void _addCharacteristic() {
    final key = _charKeyCtrl.text.trim();
    final value = _charValueCtrl.text.trim();
    if (key.isNotEmpty && value.isNotEmpty) {
      setState(() {
        _caracteristicas.add({'clave': key, 'valor': value});
        _charKeyCtrl.clear();
        _charValueCtrl.clear();
      });
    }
  }

  void _showAddModuleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Agregar Módulo de Software', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _modNombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Módulo (ej. Auth)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modDescCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción del alcance'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _modHorasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Horas est.'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _modPrecioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio sugerido'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _modNombreCtrl.clear();
              _modDescCtrl.clear();
              _modHorasCtrl.clear();
              _modPrecioCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = _modNombreCtrl.text.trim();
              if (nombre.isNotEmpty) {
                final horas = double.tryParse(_modHorasCtrl.text) ?? 0.0;
                final precio = double.tryParse(_modPrecioCtrl.text) ?? 0.0;
                setState(() {
                  _modulos.add({
                    'nombre': nombre,
                    'descripcion': _modDescCtrl.text.trim(),
                    'horas': horas,
                    'precio': precio,
                  });
                  _recalculatePrice();
                });
                _modNombreCtrl.clear();
                _modDescCtrl.clear();
                _modHorasCtrl.clear();
                _modPrecioCtrl.clear();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final precio = double.tryParse(_priceCtrl.text) ?? 0.0;

      final data = {
        'nombre': _nameCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim(),
        'tipo_cobro': _selectedTipo.value,
        'pilar': _selectedPilar.key,
        'precio_base': precio,
        'activo': widget.editItem?.activo ?? true,
        'categoria': _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
        'unidad': _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
        'imagenes_urls': _imagenesUrls,
        'imagen_url': _imagenesUrls.isNotEmpty ? _imagenesUrls.first : null,
        'caracteristicas': _caracteristicas,
      };

      // Inject Pilar specific parameters
      if (_selectedPilar == PilarNegocio.productosInventario) {
        data['costo_proveedor'] = double.tryParse(_costoCtrl.text);
        data['margen_porcentaje'] = double.tryParse(_margenCtrl.text);
        data['marca'] = _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim();
        data['modelo'] = _modeloCtrl.text.trim().isEmpty ? null : _modeloCtrl.text.trim();
        data['garantia'] = _garantiaCtrl.text.trim().isEmpty ? null : _garantiaCtrl.text.trim();
        data['dimensiones'] = _dimensionesCtrl.text.trim().isEmpty ? null : _dimensionesCtrl.text.trim();
        data['peso_kg'] = double.tryParse(_pesoCtrl.text);
        data['stock'] = double.tryParse(_stockCtrl.text) ?? 0.0;
        data['es_rezago'] = _esRezago;
      } else if (_selectedPilar == PilarNegocio.serviciosTecnicos) {
        data['modalidad_servicio'] = _modalidadServicio;
        data['incluye_visita'] = _incluyeVisita;
        data['tarifa_hora_extra'] = double.tryParse(_tarifaHoraExtraCtrl.text);
        data['duracion_estimada'] = _duracionEstimadaCtrl.text.trim().isEmpty ? null : _duracionEstimadaCtrl.text.trim();
        data['stock'] = 0.0;
        data['es_rezago'] = false;
      } else if (_selectedPilar == PilarNegocio.proyectosComplexos) {
        data['tipo_proyecto'] = _tipoProyecto;
        data['tecnologias'] = _tecnologias;
        data['modulos'] = _modulos;
        data['horas_estimadas'] = double.tryParse(_horasEstimadasCtrl.text);
        data['garantia_entrega'] = _garantiaEntregaCtrl.text.trim().isEmpty ? null : _garantiaEntregaCtrl.text.trim();
        data['es_por_puntos'] = _pilarCUseStoryPoints;
        data['puntos'] = _pilarCUseStoryPoints ? _pilarCSelectedPuntos : null;
        data['tarifa_punto'] = _pilarCUseStoryPoints ? double.tryParse(_pilarCTarifaPuntoCtrl.text) : null;
        data['stock'] = 0.0;
        data['es_rezago'] = false;
      } else if (_selectedPilar == PilarNegocio.microTransacciones) {
        data['comision_fija'] = double.tryParse(_comisionFijaCtrl.text) ?? 0.0;
        data['comision_porcentaje'] = double.tryParse(_comisionPorcentajeCtrl.text) ?? 0.0;
        data['monto_minimo'] = double.tryParse(_montoMinimoCtrl.text);
        data['monto_maximo'] = double.tryParse(_montoMaximoCtrl.text);
        data['tipo_pago'] = _tipoPago;
        data['stock'] = 0.0;
        data['es_rezago'] = false;
      } else if (_selectedPilar == PilarNegocio.serviciosCreativos) {
        data['tipo_contenido'] = _tipoContenido;
        data['revisiones_incluidas'] = int.tryParse(_revisionesCtrl.text) ?? 2;
        data['tiempo_entrega'] = _tiempoEntregaCtrl.text.trim().isEmpty ? null : _tiempoEntregaCtrl.text.trim();
        data['entregables'] = _entregables;
        data['formato_salida'] = _formatoSalidaCtrl.text.trim().isEmpty ? null : _formatoSalidaCtrl.text.trim();
        
        if (_pilarECobroScheme == 'horas') {
          data['horas_estimadas'] = double.tryParse(_pilarEHorasEstimadasCtrl.text);
          data['tarifa_hora_creativa'] = double.tryParse(_pilarETarifaHoraCtrl.text);
        } else if (_pilarECobroScheme == 'minutos') {
          data['horas_estimadas'] = double.tryParse(_pilarEMinutosCtrl.text); // save minutes count in hours column
          data['tarifa_hora_creativa'] = double.tryParse(_pilarETarifaMinutoCtrl.text); // save minute rate in hora_creativa column
        } else {
          data['horas_estimadas'] = null;
          data['tarifa_hora_creativa'] = double.tryParse(_tarifaHoraCreativaCtrl.text);
        }
        
        data['stock'] = 0.0;
        data['es_rezago'] = false;
      }

      if (widget.editItem != null) {
        await supabase.from('catalogo').update(data).eq('id', widget.editItem!.id);
      } else {
        data['id'] = const Uuid().v4();
        await supabase.from('catalogo').insert(data);
      }

      ref.invalidate(catalogItemsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(widget.editItem != null ? 'Elemento actualizado ✓' : 'Elemento registrado ✓'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _softDeleteProduct() async {
    final item = widget.editItem;
    if (item == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar de catálogo?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('El elemento se moverá a la papelera lógica y no se mostrará en el catálogo activo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('catalogo').update({'activo': false}).eq('id', item.id);
      ref.invalidate(catalogItemsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviado a papelera lógica')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al eliminar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildPilarCard(PilarNegocio pilar, IconData icon, Color color) {
    final isSelected = _selectedPilar == pilar;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPilarSelected(pilar),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceBorder,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textDisabled, size: 24),
              const SizedBox(height: 6),
              Text(
                pilar.label.split('&').first.trim().replaceFirst('KST ', ''),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editItem != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Tap outside to close keyboards
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: Text(isEditing ? 'Editar en Catálogo' : 'Nuevo en Catálogo'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isSaving
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SECTION 1: PILAR SELECTION (Visual Cards)
                      const Text(
                        'Pilar Comercial KST *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildPilarCard(PilarNegocio.productosInventario, Icons.inventory_2_outlined, AppColors.secondary),
                          const SizedBox(width: 8),
                          _buildPilarCard(PilarNegocio.serviciosTecnicos, Icons.build_circle_outlined, AppColors.accent),
                          const SizedBox(width: 8),
                          _buildPilarCard(PilarNegocio.proyectosComplexos, Icons.code_rounded, AppColors.info),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPilarCard(PilarNegocio.microTransacciones, Icons.account_balance_wallet_outlined, AppColors.warning),
                          const SizedBox(width: 8),
                          _buildPilarCard(PilarNegocio.serviciosCreativos, Icons.palette_outlined, AppColors.success),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // GENERAL CARD (Name, description, pilar info)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del Elemento *',
                                  hintText: 'Ej. Cableado Cat6 o Póliza Mensual',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descCtrl,
                                style: const TextStyle(color: AppColors.textPrimary),
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción Comercial / Alcance',
                                  hintText: 'Detalla las especificaciones técnicas o entregables del servicio...',
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<TipoCobro>(
                                isExpanded: true,
                                initialValue: _selectedTipo,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                decoration: const InputDecoration(labelText: 'Esquema de Cobro'),
                                items: TipoCobro.values
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t.label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedTipo = val);
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _unitCtrl,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Unidad de Medida',
                                  hintText: 'pza, hr, servicio, etc.',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _categoryCtrl,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Categoría Interna (Tag)',
                                  hintText: 'Ej. Redes, Consultoría, Hosting',
                                  prefixIcon: Icon(Icons.tag_rounded, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SECTION 2: DYNAMIC PRICING AND PARAMETERS PER PILAR
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildPilarSpecificForm(),
                      ),
                      const SizedBox(height: 20),

                      // SECTION 3: IMAGE GALLERY (Up to 5)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Galería de Imágenes (Máx. 5)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    '${_imagenesUrls.length}/5',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_imagenesUrls.isNotEmpty)
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _imagenesUrls.length,
                                    itemBuilder: (context, idx) {
                                      final url = _imagenesUrls[idx];
                                      return Stack(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppColors.surfaceBorder),
                                              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 12,
                                            child: GestureDetector(
                                              onTap: () => setState(() => _imagenesUrls.removeAt(idx)),
                                              child: const CircleAvatar(
                                                radius: 10,
                                                backgroundColor: AppColors.error,
                                                child: Icon(Icons.close_rounded, size: 10, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _imageUrlInputCtrl,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        labelText: 'Pegar URL de Imagen',
                                        hintText: 'https://...',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      final url = _imageUrlInputCtrl.text.trim();
                                      if (url.isNotEmpty) {
                                        if (_imagenesUrls.length < 5) {
                                          setState(() {
                                            _imagenesUrls.add(url);
                                            _imageUrlInputCtrl.clear();
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Límite de 5 imágenes alcanzado.')),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    style: IconButton.styleFrom(backgroundColor: AppColors.secondary.withValues(alpha: 0.1)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isUploadingImage)
                                const LinearProgressIndicator(color: AppColors.secondary)
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _pickAndUploadImage(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                                        label: const Text('Subir de Galería', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _pickAndUploadImage(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                        label: const Text('Tomar Foto', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SECTION 4: CUSTOM KEY-VALUE CHARACTERISTICS
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Especificaciones o Fichas Técnicas Extra',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 10),
                              if (_caracteristicas.isNotEmpty)
                                ..._caracteristicas.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final char = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${char['clave']}: ${char['valor']}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
                                          onPressed: () => setState(() => _caracteristicas.removeAt(idx)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _charKeyCtrl,
                                      decoration: const InputDecoration(labelText: 'Característica (Clave)'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _charValueCtrl,
                                      decoration: const InputDecoration(labelText: 'Valor'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: _addCharacteristic,
                                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                                    style: IconButton.styleFrom(backgroundColor: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ACTIONS
                      ElevatedButton.icon(
                        onPressed: _saveProduct,
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          isEditing ? 'Guardar Cambios' : 'Registrar en Catálogo',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      if (isEditing) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _softDeleteProduct,
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          label: const Text('Mover a la Papelera', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoBanner(String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge(Color color) {
    final double calculated = double.tryParse(_priceCtrl.text) ?? 0.0;
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

    if (_selectedPilar == PilarNegocio.microTransacciones) {
      final double pct = double.tryParse(_comisionPorcentajeCtrl.text) ?? 0.0;
      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'COMISIÓN FIJA BASE:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  fmt.format(calculated),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
                ),
              ],
            ),
            if (pct > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'COMISIÓN VARIABLE EXTRA:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${pct.toStringAsFixed(2)}% del monto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PRECIO FINAL DE VENTA:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            fmt.format(calculated),
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryPointDetailsCard(int points) {
    final Map<int, Map<String, dynamic>> storyPointMatrix = {
      1: {'esfuerzo': 'Mínimo', 'esf_level': 1, 'tiempo': 'Unos minutos', 'complejidad': 'Mínima', 'comp_level': 1, 'riesgo': 'Ninguno', 'riesgo_level': 1, 'incertidumbre': 'Mínima', 'incert_level': 1},
      2: {'esfuerzo': 'Mínimo', 'esf_level': 1, 'tiempo': '1 hora', 'complejidad': 'Mínima', 'comp_level': 1, 'riesgo': 'Ninguno', 'riesgo_level': 1, 'incertidumbre': 'Mínima', 'incert_level': 1},
      3: {'esfuerzo': 'Poco', 'esf_level': 2, 'tiempo': 'Unas pocas horas', 'complejidad': 'Baja', 'comp_level': 2, 'riesgo': 'Ninguno', 'riesgo_level': 1, 'incertidumbre': 'Baja', 'incert_level': 2},
      4: {'esfuerzo': 'Poco', 'esf_level': 2, 'tiempo': 'Menos de 1 día', 'complejidad': 'Baja', 'comp_level': 2, 'riesgo': 'Bajo', 'riesgo_level': 2, 'incertidumbre': 'Baja', 'incert_level': 2},
      5: {'esfuerzo': 'Poco', 'esf_level': 2, 'tiempo': '1 día', 'complejidad': 'Baja', 'comp_level': 2, 'riesgo': 'Bajo', 'riesgo_level': 2, 'incertidumbre': 'Baja', 'incert_level': 2},
      6: {'esfuerzo': 'Leve', 'esf_level': 3, 'tiempo': 'Pocos días', 'complejidad': 'Media', 'comp_level': 3, 'riesgo': 'Bajo', 'riesgo_level': 2, 'incertidumbre': 'Media', 'incert_level': 3},
      7: {'esfuerzo': 'Leve', 'esf_level': 3, 'tiempo': 'Menos de 1 semana', 'complejidad': 'Media', 'comp_level': 3, 'riesgo': 'Moderado', 'riesgo_level': 3, 'incertidumbre': 'Media', 'incert_level': 3},
      8: {'esfuerzo': 'Moderado', 'esf_level': 4, 'tiempo': '1 semana', 'complejidad': 'Media', 'comp_level': 3, 'riesgo': 'Moderado', 'riesgo_level': 3, 'incertidumbre': 'Media', 'incert_level': 3},
      9: {'esfuerzo': 'Moderado', 'esf_level': 4, 'tiempo': 'Menos de 2 semanas', 'complejidad': 'Media', 'comp_level': 3, 'riesgo': 'Moderado', 'riesgo_level': 3, 'incertidumbre': 'Media', 'incert_level': 3},
      10: {'esfuerzo': 'Severo', 'esf_level': 5, 'tiempo': '2 semanas', 'complejidad': 'Alta', 'comp_level': 4, 'riesgo': 'Moderado', 'riesgo_level': 3, 'incertidumbre': 'Alta', 'incert_level': 4},
      11: {'esfuerzo': 'Severo', 'esf_level': 5, 'tiempo': 'Menos de 1 mes', 'complejidad': 'Alta', 'comp_level': 4, 'riesgo': 'Alto', 'riesgo_level': 4, 'incertidumbre': 'Alta', 'incert_level': 4},
      13: {'esfuerzo': 'Alto', 'esf_level': 6, 'tiempo': '1 mes', 'complejidad': 'Alta', 'comp_level': 4, 'riesgo': 'Alto', 'riesgo_level': 4, 'incertidumbre': 'Alta', 'incert_level': 4},
      14: {'esfuerzo': 'Muy Alto', 'esf_level': 6, 'tiempo': '1-2 meses', 'complejidad': 'Muy alta', 'comp_level': 5, 'riesgo': 'Muy alto', 'riesgo_level': 5, 'incertidumbre': 'Muy alta', 'incert_level': 5},
      15: {'esfuerzo': 'Máximo', 'esf_level': 7, 'tiempo': 'Demasiado', 'complejidad': 'Extrema', 'comp_level': 5, 'riesgo': 'Demasiado', 'riesgo_level': 6, 'incertidumbre': 'Extrema', 'incert_level': 5},
    };

    final details = storyPointMatrix[points];
    if (details == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.info, size: 16),
              const SizedBox(width: 6),
              Text(
                'Métrica de Estimación: $points Puntos',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVisualGauge('Complejidad:', details['complejidad']!, details['comp_level']!, 5, AppColors.info),
          _buildVisualGauge('Incertidumbre:', details['incertidumbre']!, details['incert_level']!, 5, AppColors.secondary),
          _buildVisualGauge('Esfuerzo:', details['esfuerzo']!, details['esf_level']!, 7, AppColors.accent),
          _buildVisualGauge('Riesgo:', details['riesgo']!, details['riesgo_level']!, 6, AppColors.error),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 6),
              const Text('Tiempo Estimado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Text(details['tiempo']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualGauge(String label, String valueString, int valueLevel, int maxLevel, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                valueString,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(maxLevel, (index) {
              final active = index < valueLevel;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: active ? color : AppColors.surfaceBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPilarSpecificForm() {
    switch (_selectedPilar) {
      // 🔵 INFRAESTRUCTURA Y REDES
      case PilarNegocio.productosInventario:
        return Card(
          key: const ValueKey('pilar_a'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoBanner(
                  'KST Infraestructura & Redes',
                  'Categoría para registrar hardware físico, switches, cableado estructurado, canalizaciones o licencias comerciales.',
                  AppColors.secondary,
                ),
                const Text(
                  'Parámetros Financieros (Calculadora)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Costo Proveedor (MXN)', prefixIcon: Icon(Icons.attach_money)),
                  onChanged: (v) => _recalculatePrice(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _margenCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Margen %', prefixIcon: Icon(Icons.percent_rounded)),
                  onChanged: (v) => _recalculatePrice(),
                ),
                _buildPriceBadge(AppColors.secondary),
                const SizedBox(height: 16),
                const Text(
                  'Información de Inventario',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _marcaCtrl,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modeloCtrl,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _garantiaCtrl,
                  decoration: const InputDecoration(labelText: 'Garantía del Fabricante', hintText: 'Ej. 1 año con fabricante'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Inicial', prefixIcon: Icon(Icons.inventory_2_rounded)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.surfaceBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('¿Es producto en rezago?', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      Switch(
                        value: _esRezago,
                        onChanged: (val) => setState(() => _esRezago = val),
                        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.secondary : null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dimensionesCtrl,
                  decoration: const InputDecoration(labelText: 'Dimensiones', hintText: 'ej. 19" 1U rack'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pesoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Peso (Kg)'),
                ),
              ],
            ),
          ),
        );

      // 🛠️ SOPORTE Y MANTENIMIENTO
      case PilarNegocio.serviciosTecnicos:
        return Card(
          key: const ValueKey('pilar_b'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoBanner(
                  'KST Soporte & Mantenimiento',
                  'Servicios de diagnóstico de computadoras, pólizas mensuales de mantenimiento, soporte en sitio/remoto y limpiezas físicas.',
                  AppColors.accent,
                ),
                const Text(
                  'Tarifario del Servicio',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tarifaBaseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tarifa Base (MXN)', prefixIcon: Icon(Icons.attach_money)),
                  onChanged: (v) => _recalculatePrice(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _viaticosCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Viáticos/Visita (MXN)', prefixIcon: Icon(Icons.commute)),
                  onChanged: (v) => _recalculatePrice(),
                ),
                _buildPriceBadge(AppColors.accent),
                const SizedBox(height: 16),
                const Text(
                  'Alcance y Modalidad',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tarifaHoraExtraCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Costo Hora Extra (MXN)', prefixIcon: Icon(Icons.hourglass_empty_rounded)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _duracionEstimadaCtrl,
                  decoration: const InputDecoration(labelText: 'Duración Estimada', hintText: 'ej. 2-4 horas o Medio Día'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Modalidad:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    ...['remoto', 'presencial', 'hibrido'].map((mod) {
                      final isSelected = _modalidadServicio == mod;
                      return ChoiceChip(
                        label: Text(mod.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary)),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        onSelected: (val) {
                          if (val) setState(() => _modalidadServicio = mod);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('¿Requiere visita o viáticos incluidos?', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  value: _incluyeVisita,
                  onChanged: (val) {
                    setState(() {
                      _incluyeVisita = val;
                      _recalculatePrice();
                    });
                  },
                  activeThumbColor: AppColors.accent,
                ),
              ],
            ),
          ),
        );

      // 💻 SOFTWARE Y PLATAFORMAS
      case PilarNegocio.proyectosComplexos:
        return Card(
          key: const ValueKey('pilar_c'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoBanner(
                  'KST Software & Plataformas',
                  'Desarrollo a la medida de aplicaciones móviles, portales web responsive, integraciones de API, ERPs corporativos y scripts.',
                  AppColors.info,
                ),
                const Text(
                  'Esquema de Estimación / Cotización',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.info, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.hourglass_bottom, size: 14),
                        label: const Text('Por Horas y Módulos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: !_pilarCUseStoryPoints,
                        selectedColor: AppColors.info.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _pilarCUseStoryPoints = false;
                              _recalculatePrice();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.analytics, size: 14),
                        label: const Text('Por Story Points', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: _pilarCUseStoryPoints,
                        selectedColor: AppColors.info.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _pilarCUseStoryPoints = true;
                              _recalculatePrice();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_pilarCUseStoryPoints) ...[
                  TextFormField(
                    controller: _tarifaHoraCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tarifa Hora (MXN)', prefixIcon: Icon(Icons.attach_money)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _horasEstimadasCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Horas Estimadas Proyecto', prefixIcon: Icon(Icons.timer_outlined)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                ] else ...[
                  const Text('Selecciona Story Points de la Matriz:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15].map((points) {
                      final isSelected = _pilarCSelectedPuntos == points;
                      
                      // Color code by complexity level
                      Color pointColor;
                      if (points <= 3) {
                        pointColor = AppColors.success;
                      } else if (points <= 5) {
                        pointColor = AppColors.info;
                      } else if (points <= 9) {
                        pointColor = AppColors.secondary;
                      } else if (points <= 13) {
                        pointColor = AppColors.warning;
                      } else {
                        pointColor = AppColors.error;
                      }
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _pilarCSelectedPuntos = points;
                            _recalculatePrice();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? pointColor : pointColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.white : pointColor,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: pointColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ] : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : pointColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pilarCTarifaPuntoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tarifa por Punto (MXN)', prefixIcon: Icon(Icons.payments_outlined)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                ],
                if (_pilarCUseStoryPoints && _pilarCSelectedPuntos != null)
                  _buildStoryPointDetailsCard(_pilarCSelectedPuntos!),
                _buildPriceBadge(AppColors.info),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Proyecto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoProyecto,
                        items: ['web', 'movil', 'desktop', 'api', 'automatizacion', 'erp', 'otro']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 11))))
                            .toList(),
                        onChanged: (v) => setState(() => _tipoProyecto = v ?? 'web'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _garantiaEntregaCtrl,
                  decoration: const InputDecoration(labelText: 'Garantía del Código Fuente', hintText: 'Ej. 90 días naturales post-liberación'),
                ),
                const SizedBox(height: 16),
                const Text('Stack Tecnológico utilizado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                if (_tecnologias.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tecnologias.map((tech) {
                      return InputChip(
                        label: Text(tech, style: const TextStyle(fontSize: 11)),
                        onDeleted: () => setState(() => _tecnologias.remove(tech)),
                        backgroundColor: AppColors.info.withValues(alpha: 0.1),
                        deleteIconColor: AppColors.error,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _techInputCtrl,
                        decoration: const InputDecoration(labelText: 'Agregar Tecnología (ej. Flutter)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _addTechChip,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Módulos / Épicas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    TextButton.icon(
                      onPressed: _showAddModuleDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Agregar Módulo'),
                    ),
                  ],
                ),
                if (_modulos.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _modulos.length,
                    itemBuilder: (ctx, idx) {
                      final mod = _modulos[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mod['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                  if (mod['descripcion'] != null && mod['descripcion'].isNotEmpty)
                                    Text(mod['descripcion'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text('${mod['horas']} hrs  •  \$${(mod['precio'] as num).toStringAsFixed(0)} MXN', style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                              onPressed: () {
                                setState(() {
                                  _modulos.removeAt(idx);
                                  _recalculatePrice();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );

      // 💸 FINANZAS Y PAGOS
      case PilarNegocio.microTransacciones:
        return Card(
          key: const ValueKey('pilar_d'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoBanner(
                  'KST Finanzas & Pagos',
                  'Servicios transaccionales, cobro de servicios (luz, agua, teléfono) o recargas de saldo con comisión fija y porcentual.',
                  AppColors.warning,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _tipoPago,
                  decoration: const InputDecoration(labelText: 'Tipo de Pago / Servicio'),
                  items: ['cfe', 'agua', 'telefono', 'recarga', 'transferencia', 'predial', 'seguro', 'otro']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoPago = v ?? 'cfe'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comisiones de Transacción',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comisionFijaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Comisión Fija (MXN)', prefixIcon: Icon(Icons.attach_money)),
                  onChanged: (v) => _recalculatePrice(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _comisionPorcentajeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Comisión % de Transacción', prefixIcon: Icon(Icons.percent_rounded)),
                  onChanged: (v) => _recalculatePrice(),
                ),
                _buildPriceBadge(AppColors.warning),
                const SizedBox(height: 16),
                const Text(
                  'Límites de Operación',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _montoMinimoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto Mínimo de Operación'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montoMaximoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto Máximo de Operación'),
                ),
              ],
            ),
          ),
        );

      // 🎬 MEDIA Y SERVICIOS CREATIVOS
      case PilarNegocio.serviciosCreativos:
        return Card(
          key: const ValueKey('pilar_e'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoBanner(
                  'KST Media & Servicios Creativos',
                  'Identidad corporativa, producción audiovisual (videos corporativos), fotografía comercial, animaciones y diseño gráfico.',
                  AppColors.success,
                ),
                const Text(
                  'Esquema de Cobro Creativo',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.inventory_2_outlined, size: 14),
                        label: const Text('Paquete Fijo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        selected: _pilarECobroScheme == 'paquete',
                        selectedColor: AppColors.success.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _pilarECobroScheme = 'paquete';
                              _recalculatePrice();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.timer_outlined, size: 14),
                        label: const Text('Por Horas', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        selected: _pilarECobroScheme == 'horas',
                        selectedColor: AppColors.success.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _pilarECobroScheme = 'horas';
                              _recalculatePrice();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.movie_creation_outlined, size: 14),
                        label: const Text('Por Minuto', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        selected: _pilarECobroScheme == 'minutos',
                        selectedColor: AppColors.success.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _pilarECobroScheme = 'minutos';
                              _recalculatePrice();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pilarECobroScheme == 'paquete') ...[
                  TextFormField(
                    controller: _tarifaBasePaqueteCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tarifa Base Paquete (MXN)', prefixIcon: Icon(Icons.attach_money)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tarifaHoraCreativaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Costo por Hora Creativa Extra (MXN)', prefixIcon: Icon(Icons.payments_outlined)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                ] else if (_pilarECobroScheme == 'horas') ...[
                  TextFormField(
                    controller: _pilarETarifaHoraCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tarifa por Hora Creativa (MXN)', prefixIcon: Icon(Icons.payments_outlined)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pilarEHorasEstimadasCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Horas Creativas Estimadas / Proyecto', prefixIcon: Icon(Icons.timer_outlined)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _pilarETarifaMinutoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tarifa por Minuto de Video/Audio (MXN)', prefixIcon: Icon(Icons.payments_outlined)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pilarEMinutosCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Minutos de Producción Estimados', prefixIcon: Icon(Icons.movie_outlined)),
                    onChanged: (v) => _recalculatePrice(),
                  ),
                ],
                _buildPriceBadge(AppColors.success),
                const SizedBox(height: 16),
                const Text(
                  'Características Técnicas',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tipoContenido,
                  decoration: const InputDecoration(labelText: 'Tipo de Contenido'),
                  items: ['video', 'diseno', 'fotografia', 'animacion', 'audio', 'branding', 'otro']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 11))))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoContenido = v ?? 'video'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _revisionesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Revisiones Incluidas en Paquete'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tiempoEntregaCtrl,
                  decoration: const InputDecoration(labelText: 'Tiempo Estimado de Entrega', hintText: 'Ej. 3-5 días hábiles'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formatoSalidaCtrl,
                  decoration: const InputDecoration(labelText: 'Formato de Entrega / Salida', hintText: 'Ej. MP4 1080p, PNG'),
                ),
                const SizedBox(height: 20),
                const Text('Entregables específicos del Paquete:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                if (_entregables.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _entregables.length,
                    itemBuilder: (ctx, idx) {
                      final item = _entregables[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 16),
                              onPressed: () => setState(() => _entregables.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _entregableInputCtrl,
                        decoration: const InputDecoration(labelText: 'Agregar Entregable (ej. Video 30s)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _addEntregable,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }
}
