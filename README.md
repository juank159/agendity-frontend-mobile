📱 Login & Signup App

Este es un proyecto de autenticación en Flutter con un backend desarrollado en Node.js y NestJS. Implementa autenticación con correo y contraseña, inicio de sesión con Google, almacenamiento seguro y manejo de notificaciones.

🚀 Tecnologías Utilizadas

🖥️ Backend

Node.js con NestJS

Base de datos: PostgreSQL (con Type ORM)

Autenticación con JWT

📱 Frontend (Flutter)

Flutter 3.5.4

GetX para manejo de estado

Dio para peticiones HTTP

Firebase para autenticación y notificaciones push

Flutter Secure Storage para almacenamiento seguro

Syncfusion para calendario y gestión de eventos

URL Launcher para abrir WhatsApp desde la app

📂 Estructura del Proyecto

login_signup/
│-- lib/
│ ├── main.dart # Punto de entrada de la app
│ ├── screens/ # Pantallas principales de la app
│ ├── services/ # Lógica de conexión con el backend
│ ├── utils/ # Funciones y configuraciones auxiliares
│ ├── widgets/ # Componentes reutilizables
│-- assets/
│ ├── images/ # Imágenes y logos
│ ├── icon.png # Ícono de la aplicación
│-- .env # Variables de entorno
│-- pubspec.yaml # Dependencias y configuración de Flutter

⚙️ Instalación

1️⃣ Configurar el Backend

Requisitos: Tener instalado Node.js y PostgreSQL

git clone https://github.com/tuusuario/backend.git
cd backend
npm install
cp .env.example .env # Configura tus variables de entorno
npx prisma migrate dev
npm run start:dev

2️⃣ Configurar el Frontend

Requisitos: Tener instalado Flutter 3.5.4

git clone https://github.com/tuusuario/login_signup.git
cd login_signup
flutter pub get
cp .env.example .env # Configura las variables de entorno
flutter run

🔔 Funcionalidades

✅ Registro e inicio de sesión con correo y contraseña✅ Autenticación con Google✅ Manejo de tokens JWT✅ Almacenamiento seguro con flutter_secure_storage✅ Notificaciones push con Firebase Cloud Messaging✅ Integración con WhatsApp para recordatorios✅ Sincronización de eventos con Syncfusion Calendar

📜 Dependencias Principales

dependencies:
flutter:
sdk: flutter
get: ^4.6.6
dio: ^5.7.0
firebase_core: ^2.15.1
firebase_auth: ^4.7.3
firebase_messaging: ^14.6.7
flutter_secure_storage: ^9.2.2
syncfusion_flutter_calendar: ^28.2.9
url_launcher: ^6.3.1

📩 Contacto

Si tienes dudas o sugerencias, ¡contáctame en tuemail@example.com!
