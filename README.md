# Agendity Mobile 📱

![Agendity Logo](assets/images/icon.png)

## Aplicación de gestión de citas y servicios profesionales

**Agendity Mobile** es una aplicación móvil desarrollada en Flutter que permite a profesionales y negocios gestionar citas, servicios, empleados y clientes desde cualquier dispositivo. Con una interfaz intuitiva y fluida, Agendity simplifica el día a día de profesionales independientes y pequeños negocios.

## ✨ Características principales

- **👥 Gestión de clientes**: Importación de contactos, historial de citas y perfiles personalizados
- **📅 Calendario de citas**: Vista por día, semana y mes usando Syncfusion Calendar
- **💼 Administración de servicios y categorías**: Organiza tus servicios por categorías
- **👨‍💼 Gestión de empleados y profesionales**: Administra el personal y sus disponibilidades
- **📊 Estadísticas y reportes**: Visualización de ingresos, citas y clientes frecuentes
- **💬 Integración con WhatsApp**: Envío automático de recordatorios y confirmaciones
- **🔔 Notificaciones push**: Mantén informados a clientes y empleados

## 🚀 Tecnologías utilizadas

### 📱 Frontend (Flutter)

- **Flutter 3.5.4**
- **GetX** para gestión de estado y navegación
- **Arquitectura por capas**: Domain, Data, Presentation (Clean Architecture)
- **Dio** para peticiones HTTP
- **Syncfusion** para calendario y visualización de datos
- **Firebase** para autenticación y notificaciones
- **Flutter Secure Storage** para almacenamiento seguro

### 🖥️ Backend

- **Node.js con NestJS**
- **PostgreSQL** con TypeORM
- **JWT** para autenticación
- **WebSockets** para actualizaciones en tiempo real
- **Firebase Cloud Messaging** para notificaciones push

## 📂 Estructura del proyecto

```
agendity-mobile/
│
├── lib/
│   ├── main.dart                   # Punto de entrada de la aplicación
│   ├── config/                     # Configuraciones globales
│   ├── core/                       # Funcionalidades centrales, independientes de dominio
│   │   ├── api/                    # Configuración de conexión con API
│   │   ├── error/                  # Manejo de errores
│   │   └── storage/                # Almacenamiento local seguro
│   │
│   ├── features/                   # Módulos de la aplicación
│   │   ├── auth/                   # Autenticación (login, registro)
│   │   ├── appointments/           # Gestión de citas
│   │   ├── clients/                # Administración de clientes
│   │   ├── services/               # Gestión de servicios
│   │   ├── employees/              # Administración de empleados
│   │   ├── statistics/             # Estadísticas y reportes
│   │   └── whatsapp/               # Configuración de WhatsApp
│   │
│   ├── shared/                     # Elementos compartidos entre módulos
│   │   ├── components/             # Widgets reutilizables
│   │   ├── theme/                  # Tema y estilos globales
│   │   └── utils/                  # Utilidades y helpers
│   │
│   └── routes/                     # Configuración de navegación
│
├── assets/                         # Recursos estáticos
│   ├── images/                     # Imágenes e iconos
│   └── fonts/                      # Fuentes personalizadas
│
├── .env                            # Variables de entorno
└── pubspec.yaml                    # Dependencias del proyecto
```

## ⚙️ Instalación y configuración

### Prerrequisitos

- Flutter 3.5.4 o superior
- Java 17 para el desarrollo Android
- Xcode para el desarrollo iOS
- Firebase CLI (para configurar notificaciones)

### Configuración del proyecto

1. **Clonar el repositorio**

   ```bash
   git clone https://github.com/tuusuario/agendity-mobile.git
   cd agendity-mobile
   ```

2. **Instalar dependencias**

   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**

   ```bash
   cp .env.example .env
   # Edita el archivo .env con tus propias configuraciones
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📦 Dependencias principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Gestión de estado y DI
  get: ^4.6.6

  # Interfaz de usuario
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.16
  hexcolor: ^3.0.1

  # Calendario y fechas
  syncfusion_flutter_calendar: ^28.2.9
  syncfusion_flutter_core: ^28.2.9
  syncfusion_flutter_datepicker: ^28.2.9
  intl: ^0.19.0

  # Red y almacenamiento
  dio: ^5.7.0
  http_parser: ^4.0.2
  flutter_secure_storage: ^9.2.2
  flutter_dotenv: ^5.2.1

  # Gráficos y visualización de datos
  fl_chart: ^0.65.0

  # Firebase y autenticación
  firebase_core: ^2.32.0
  firebase_messaging: ^14.7.10
  firebase_auth: ^4.16.0
  google_sign_in: ^6.2.2

  # Utilidades
  permission_handler: ^11.3.1
  internet_connection_checker: ^1.0.0
  url_launcher: ^6.3.1
  flutter_contacts: ^1.1.9+2
  image_picker: ^1.1.2
  dartz: ^0.10.1
```

## 🖼️ Capturas de pantalla

<div style="display: flex; flex-wrap: wrap; gap: 10px; justify-content: center;">
  <img src="assets/screenshots/login.png" width="200" alt="Pantalla de login"/>
  <img src="assets/screenshots/dashboard.png" width="200" alt="Dashboard"/>
  <img src="assets/screenshots/calendar.png" width="200" alt="Calendario"/>
  <img src="assets/screenshots/services.png" width="200" alt="Servicios"/>
</div>

## 🧪 Pruebas

```bash
# Ejecutar pruebas unitarias
flutter test

# Ejecutar pruebas de integración
flutter drive --target=test_driver/app.dart
```

## 👥 Contribuciones

Las contribuciones son bienvenidas. Por favor, sigue estos pasos:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/amazing-feature`)
3. Haz commit de tus cambios (`git commit -m 'Add some amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 📬 Contacto

Si tienes preguntas o sugerencias, no dudes en contactarnos:

- Email: contacto@tuempresa.com
- Twitter: [@agendityapp](https://twitter.com/agendityapp)
- Sitio web: [www.agendity.com](https://www.agendity.com)

---

<p align="center">
  Desarrollado con ❤️ por <a href="https://github.com/juank159">Tu Nombre</a>
</p>
