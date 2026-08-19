# 💼 KST Business — Intelligent Enterprise Quotation & Proposal App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_2.6-2E7D32?style=for-the-badge)](https://riverpod.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![PDF Engine](https://img.shields.io/badge/PDF_Engine-Automated_Quotes-D32F2F?style=for-the-badge)](https://pub.dev/packages/pdf)
[![GoRouter](https://img.shields.io/badge/Navigation-GoRouter_14-7B1FA2?style=for-the-badge)](https://pub.dev/packages/go_router)

<p align="center">
  <b>KST Business</b> es una aplicación móvil corporativa desarrollada para <b>Key Solutions Technology</b> para agilizar la cotización, cálculo de costos y emisión automatizada de propuestas comerciales.
</p>

</div>

---

## 📌 Visión General

La plataforma elimina errores humanos en la estimación de proyectos de software y servicios de TI, permitiendo al equipo comercial estructurar cotizaciones detalladas y generar contratos / PDFs profesionales en segundos desde cualquier dispositivo móvil.

### 🌟 Capacidades Principales

* 📑 **Motor de Cotización Inteligente:** Formularios dinámicos y validados (`flutter_form_builder`) con desglose de costos, impuestos y márgenes de utilidad en tiempo real.
* 📄 **Generador Automatizado de Documentos PDF:** Emisión de propuestas comerciales con membrete institucional, firmas digitales y tablas de entregables listas para compartir (`pdf` / `printing`).
* ⚡ **Navegación Declarativa & Gestión de Estado:** Implementación con **GoRouter** y **Riverpod 2.6** (con code generation) para una arquitectura limpia y testeable.
* ✨ **UI/UX Moderna y Dinámica:** Micro-interacciones con `flutter_animate`, animaciones vectoriales `Lottie` y fuentes tipográficas optimizadas con `Google Fonts`.
* ☁️ **Sincronización en la Nube:** Almacenamiento seguro de clientes, catálogos de servicios e historial de cotizaciones en **Supabase**.

---

## 🛠️ Stack Tecnológico

| Módulo | Tecnologías |
| :--- | :--- |
| **Framework** | Flutter 3.x / Dart |
| **State Management** | Riverpod 2.6 & Riverpod Annotation |
| **Routing & Forms** | GoRouter 14.8, Form Builder & Validators |
| **UI & Animación** | Google Fonts, Flutter Animate, Lottie, Shimmer |
| **Backend & Cloud** | Supabase Flutter SDK (Auth, Database, Storage) |
| **Document Export** | PDF, Printing, Path Provider |

---

## 🚀 Puesta en Marcha

```bash
# 1. Clonar el repositorio
git clone https://github.com/ricardomtnez/kst_business.git
cd kst_business

# 2. Instalar dependencias
flutter pub get

# 3. Generar código de Riverpod (si aplica)
dart run build_runner build --delete-conflicting-outputs

# 4. Ejecutar la aplicación
flutter run
```

---

## 👨‍💻 Autor
**Ricardo Martínez** — [@ricardomtnez](https://github.com/ricardomtnez) | [LinkedIn](https://www.linkedin.com/in/ricardomtnezhdez/)
