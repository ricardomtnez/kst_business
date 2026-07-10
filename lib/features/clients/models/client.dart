// lib/data/models/client.dart

import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final String id;
  final String nombre;
  final String? telefono;
  final String? correo;
  final String? empresa;
  final String? rfc;
  final DateTime? creadoEn;

  const Client({
    required this.id,
    required this.nombre,
    this.telefono,
    this.correo,
    this.empresa,
    this.rfc,
    this.creadoEn,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        telefono: json['telefono'] as String?,
        correo: json['correo'] as String?,
        empresa: json['empresa'] as String?,
        rfc: json['rfc'] as String?,
        creadoEn: json['creado_en'] != null
            ? DateTime.tryParse(json['creado_en'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'correo': correo,
        'empresa': empresa,
        'rfc': rfc,
        'creado_en': creadoEn?.toIso8601String(),
      };

  String get displayName => empresa != null ? '$nombre ($empresa)' : nombre;
  String get initials {
    final parts = nombre.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, nombre, correo, telefono];
}
