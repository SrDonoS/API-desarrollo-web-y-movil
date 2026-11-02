<h1 align="center">📚 Biblioteca Comunitaria</h1>

<p align="center">
  <b>API REST + App Android para prestar libros en la biblioteca del barrio</b><br>
  <i>Hecha con harto cariño, café y uno que otro 409 💥</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Flask-3.x-000000?logo=flask&logoColor=white" alt="Flask">
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white" alt="MySQL">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Android-app-3DDC84?logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/JWT-auth-000000?logo=jsonwebtokens&logoColor=white" alt="JWT">
  <img src="https://img.shields.io/badge/AWS-próximamente-FF9900?logo=amazonaws&logoColor=white" alt="AWS">
</p>

---

## 👋 ¿Qué onda con este proyecto?

La biblioteca comunitaria presta **libros físicos** a sus socios, y hasta ahora todo se anotaba en un cuaderno (o en la memoria de la tía de la biblioteca 😅). Este proyecto lo pasa a digital:

- 🐍 Una **API REST** en Flask que guarda todo en **MySQL**.
- 📱 Una **app Android** hecha en **Flutter**, para socios y bibliotecarios.
- ☁️ Y pronto, todo arriba en **AWS** pa' que funcione de verdad, no solo en el notebook.

> 📜 **La regla de oro del equipo:** *primero el contrato, después el código.*
> La planilla de especificación (16 endpoints, 68 respuestas, 13 de 13 contadores en OK) es **la fuente de verdad**. Si algo no está en la planilla, no se programa. Si hay que cambiar algo, se cambia primero en la planilla. Así de simple, cachai.

---

## 🚀 Partida rápida (si ya tienes todo instalado)

```bash
# 🐬 1. Base de datos (una vez): corre backend/sql/crear_base.sql en MySQL Workbench
#       o, con Docker:  cd backend && docker compose up -d

# 🐍 2. API
cd backend
python -m venv venv && venv\Scripts\activate     # (Linux/Mac: source venv/bin/activate)
pip install -r requirements.txt
copy .env.example .env                           # (Linux/Mac: cp) y ponle tu JWT_SECRET_KEY
flask --app run init-db                          # crea las tablas + datos de prueba
python run.py                                    # 👉 http://127.0.0.1:5000/docs

# 📱 3. App (otra terminal, con el emulador abierto)
cd app_movil
flutter create --org cl.biblioteca --project-name biblioteca_app --platforms android .
flutter pub get
flutter run
```

Entra con `biblio@biblioteca.cl` / `biblio1234` (bibliotecaria) o `ana.rojas@correo.cl` / `clave-segura-123` (socia) y a jugar 🎉.

> 📮 **¿El profe pide ingresar y listar datos con Postman?** Importa `postman/Biblioteca_Comunitaria.postman_collection.json` (34 peticiones listas) y sigue la guía [`docs/Guia_Postman.md`](docs/Guia_Postman.md): explica desde cero qué es una API, cómo funciona nuestro código y Postman paso a paso.

---

## 🧭 Contenido

1. [Las reglas del negocio](#-las-reglas-del-negocio)
2. [Arquitectura](#️-arquitectura)
3. [Stack](#-stack)
4. [Estructura del repo](#-estructura-del-repo)
5. [Levantar el backend en tu compu](#-levantar-el-backend-en-tu-compu)
6. [Levantar la app Flutter](#-levantar-la-app-flutter)
7. [Endpoints](#-endpoints)
8. [Seguridad: quién puede hacer qué](#-seguridad-quién-puede-hacer-qué)
9. [Errores: cómo responde la API cuando algo falla](#-errores-cómo-responde-la-api-cuando-algo-falla)
10. [Pruebas](#-pruebas)
11. [Rumbo a AWS](#️-rumbo-a-aws)
12. [Roadmap](#️-roadmap)
13. [Cómo trabajamos (git)](#-cómo-trabajamos-git)
14. [Equipo](#-equipo)

---

## 📏 Las reglas del negocio

| Regla | Cómo la cumple la API |
|---|---|
| 📖 Cada libro tiene autor, categoría y **varias copias físicas** | Se presta la **copia** (con su `codigo_inventario`), no "el libro" |
| 🔢 Un socio puede tener **máximo 3 préstamos activos** | El 4.º préstamo responde **409** `LIMITE_PRESTAMOS` |
| 📅 Los préstamos duran **14 días** | El servidor calcula `fecha_vencimiento = hoy + 14` |
| 💸 Los atrasos generan **multa** | Al devolver con atraso: **$500 por día** (decisión del equipo, vive en la config) |
| 👩‍💼 El personal registra préstamos y devoluciones | Solo el rol **bibliotecario** (los demás reciben **403**) |
| 🙋 El socio ve el catálogo y **solo SUS préstamos** | `GET /api/mis-prestamos` no recibe id: el socio sale del token 🔐 |

**Roles:** 🌍 Anónimo (solo registrarse e iniciar sesión) · 🙋 Socio · 👩‍💼 Bibliotecario.

---

## 🏗️ Arquitectura

**En local (desarrollo):**

```
 ┌────────────────────┐   HTTP + JSON    ┌──────────────────────┐   SQL    ┌──────────────┐
 │ 📱 App Flutter      │  ─────────────▶  │ 🐍 API Flask         │ ───────▶ │ 🐬 MySQL 8    │
 │  (emulador Android) │  Bearer <JWT>    │  python run.py :5000 │ PyMySQL  │  localhost   │
 └────────────────────┘  ◀─────────────  └──────────────────────┘          └──────────────┘
```

**En AWS (producción, la meta 🎯):**

```
 📱 App Android ──HTTPS──▶ 🌐 Nginx (EC2) ──▶ 🦄 Gunicorn + Flask (EC2) ──▶ 🐬 Amazon RDS MySQL
                           Elastic IP / dominio                              (subred privada, sin acceso público)
```

La app **no sabe nada de MySQL**: solo habla con la API. Y la API **no guarda sesiones**: cada petición trae su token JWT, así que se puede escalar sin drama.

---

## 🧰 Stack

| Capa | Tecnología | ¿Pa' qué? |
|---|---|---|
| 🐍 Backend | **Flask 3** | El framework que vimos en clase |
| 🗃️ ORM | **SQLAlchemy** + **Flask-Migrate** | Modelos en Python y migraciones (`flask db upgrade`) |
| ✅ Validación | **Marshmallow** + **flask-smorest** | Valida entradas, arma las respuestas y genera **Swagger** solito |
| 🔑 Auth | **flask-jwt-extended** | Tokens JWT con el rol adentro |
| 🐬 Base de datos | **MySQL 8** (driver **PyMySQL**) | Lo que pidió el profe |
| 🦄 Servidor prod | **Gunicorn** (+ Nginx) | `python run.py` es solo para desarrollo |
| 📱 App | **Flutter 3** (Dart), target **Android** | Una sola base de código, app nativa |
| 🌐 HTTP en la app | `http` (o `dio`) | Hablar con la API |
| 🔒 Token en la app | `flutter_secure_storage` | Guardar el JWT cifrado en el teléfono (nunca en texto plano) |
| ☁️ Nube | **AWS**: EC2 + RDS | Próxima etapa |

---

## 📁 Estructura del repo

```
biblioteca-comunitaria/
├── README.md                          ← estás aquí 👋
├── .gitignore                         (.env, venv, build, apk… nunca a git)
├── docs/
│   ├── Donovan & Carlos Planilla_Especificacion_API.xlsx   ← 📜 EL CONTRATO (fuente de verdad)
│   ├── Guia_Estudio_API.md            ← la guía para entender cada endpoint
│   └── Guia_Postman.md                ← 📮 ingresar y listar datos con Postman
│
├── postman/
│   └── Biblioteca_Comunitaria.postman_collection.json   ← 34 peticiones listas pa' importar
│
├── backend/                           ← 🐍 API Flask + MySQL
│   ├── run.py                         python run.py (dev) · gunicorn run:app (AWS)
│   ├── requirements.txt               versiones fijadas y probadas juntas
│   ├── requirements-dev.txt           + pytest
│   ├── .env.example                   plantilla de variables (el .env real NO se sube)
│   ├── docker-compose.yml             MySQL 8 en Docker (opcional)
│   ├── sql/crear_base.sql             crea la base, la de pruebas y el usuario
│   ├── migrations/                    tablas versionadas (Flask-Migrate / Alembic)
│   ├── tests/                         pytest: las 68 respuestas del contrato
│   └── app/
│       ├── __init__.py                crear_app()
│       ├── config.py                  todo sale de variables de entorno
│       ├── extensiones.py             db, migrate, api, jwt, cors
│       ├── tiempo.py                  ahora() / hoy() en hora de Chile (AWS anda en UTC)
│       ├── errores.py                 formato único de error (+ "motivo" en los 409)
│       ├── seguridad.py               @bibliotecario_requerido (401 / 403)
│       ├── comandos.py                flask init-db · flask crear-bibliotecario
│       ├── modelos.py                 Usuario, Categoria, Libro, Copia, Prestamo, Multa
│       ├── esquemas.py                validación (entrada) y serialización (salida)
│       └── rutas/
│           ├── auth.py                E01 E02 E03
│           ├── libros.py              E04 E05 E06 E07 E08 E09
│           ├── categorias.py          E10 E11
│           ├── prestamos.py           E12 E13 E14
│           ├── mis_prestamos.py       E15
│           └── multas.py              E16
│
├── app_movil/                         ← 📱 App Flutter (Android)
│   ├── pubspec.yaml                   http · provider · flutter_secure_storage
│   ├── android/app/src/main/AndroidManifest.xml   permiso INTERNET + http en desarrollo
│   ├── test/                          modelos, widgets y (opcional) contra la API real
│   └── lib/
│       ├── main.dart                  decide: splash · login · inicio
│       ├── config/api_config.dart     URL de la API (vía --dart-define)
│       ├── core/                      api_client (el único que habla HTTP), errores, token
│       ├── models/                    usuario, libro, copia, prestamo, multa, pagina
│       ├── services/                  auth, libros, categorias, prestamos (1 método = 1 endpoint)
│       ├── providers/sesion.dart      quién está conectado (y qué pasa con un 401)
│       ├── utils/                     formatos ($1.500, 27-10-2026), mensajes, validaciones
│       ├── widgets/                   chips de estado, tarjeta de préstamo, diálogos
│       └── screens/
│           ├── auth/                  🌍 login · registro
│           ├── catalogo/              🙋👩‍💼 catálogo · detalle · formulario de libro
│           ├── prestamos/             🙋 mis préstamos
│           ├── biblio/                👩‍💼 préstamos de todos · nuevo préstamo
│           └── perfil_screen.dart     número de socio y cerrar sesión
│
└── deploy/aws/                        ← ☁️ todo pa' subirlo a AWS
    ├── README.md                      paso a paso: RDS, EC2, Elastic IP, HTTPS
    ├── instalar_en_ec2.sh             instala la API en un Ubuntu 24.04
    ├── biblioteca-api.service         Gunicorn como servicio (systemd)
    └── nginx-biblioteca.conf          Nginx adelante de Gunicorn
```

---

## 🐍 Levantar el backend en tu compu

### ✅ Lo que necesitas

- **Python 3.11+**
- **MySQL 8.0** (MySQL Server + Workbench, o Docker)
- **Git**

### 1️⃣ Crear la base de datos

Abre MySQL Workbench (o la consola `mysql -u root -p`) y corre el archivo **`backend/sql/crear_base.sql`**. Hace esto (más una base `biblioteca_test` para las pruebas):

```sql
CREATE DATABASE biblioteca
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

CREATE USER 'biblio_app'@'localhost' IDENTIFIED BY 'cambia-esta-clave';
GRANT ALL PRIVILEGES ON biblioteca.* TO 'biblio_app'@'localhost';
FLUSH PRIVILEGES;
```

> 🇨🇱 **¿Por qué `utf8mb4`?** Pa' que las ñ y los tildes no se transformen en `Ã±` y otras cosas feas. Con la collation `_ai_ci` además, buscar `garcia` encuentra a **García** y `NOVELA` choca con `Novela` (justo lo que dice el contrato).
>
> 🐳 **¿Con Docker?** Al tiro, ya viene el `docker-compose.yml` (crea las dos bases y el usuario):
> ```bash
> cd backend
> docker compose up -d
> ```
>
> 🟠 **¿Usai XAMPP?** Ojo que XAMPP trae **MariaDB**, no MySQL. Funciona igual con PyMySQL, pero usa `COLLATE utf8mb4_unicode_ci` (MariaDB no tiene la `0900`).

### 2️⃣ Entorno virtual y dependencias

```bash
cd backend
python -m venv venv

venv\Scripts\activate            # 🪟 Windows
source venv/bin/activate         # 🐧 Linux / 🍎 macOS

pip install -r requirements.txt
```

El `requirements.txt` trae las **versiones exactas** con las que se probó todo (Flask 3.1, SQLAlchemy 2.1, flask-smorest, flask-jwt-extended, PyMySQL, cryptography, python-dotenv, tzdata y gunicorn). Así en tu compu, en la de tu compañero y en AWS corre exactamente lo mismo. 🎯

> ⚠️ **No te saltís `cryptography`:** MySQL 8 usa por defecto la autenticación `caching_sha2_password`, y PyMySQL la necesita. Sin ella, te sale un error de que falta el paquete `cryptography` y quedai mirando el techo 🙃.
>
> 🦄 **`gunicorn`** no corre en Windows, pero no importa: es pa' AWS. En tu compu usai `python run.py`.
>
> 🕐 **`tzdata`** es pa' Windows: ahí Python no trae las zonas horarias y `ZoneInfo("America/Santiago")` se cae sin este paquete.

### 3️⃣ Variables de entorno

Copia la plantilla y ajústala:

```bash
copy .env.example .env           # 🪟 Windows
cp .env.example .env             # 🐧 / 🍎
```

```ini
# .env  — NUNCA se sube a git 🙅
DATABASE_URL=mysql+pymysql://biblio_app:cambia-esta-clave@localhost:3306/biblioteca?charset=utf8mb4
JWT_SECRET_KEY=pega-aqui-una-clave-larga-y-random
ZONA_HORARIA=America/Santiago

# Reglas del negocio (vienen del contrato)
MAX_PRESTAMOS_ACTIVOS=3
DIAS_PRESTAMO=14
MULTA_POR_DIA=500
```

> 🧩 **Detalle importante:** `config.py` parte con `from dotenv import load_dotenv` y `load_dotenv()`. Los comandos `flask ...` leen el `.env` solos, pero `python run.py` arma la config **antes** de leerlo, y sin esas dos líneas la API trataría de conectarse a una base que no existe.

Pa' generar una `JWT_SECRET_KEY` decente (mínimo 32 caracteres):

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

### 4️⃣ Crear las tablas y cargar datos de prueba

Las migraciones **ya vienen hechas** en `migrations/` (no hay que correr `db init` ni `db migrate`). Un solo comando:

```bash
flask --app run init-db
```

```
🗃️  Tablas al día (migraciones aplicadas).
👤 3 usuarios de prueba:
     bibliotecario  biblio@biblioteca.cl     / biblio1234
     socio          ana.rojas@correo.cl      / clave-segura-123
     socio          pedro.soto@correo.cl     / clave-segura-123
📚 5 categorías, 8 libros y 15 copias.
```

| Comando | Pa' qué |
|---|---|
| `flask --app run init-db` | Migraciones + datos de prueba (**desarrollo**) |
| `flask --app run init-db --sin-datos` | Solo las tablas (**producción / AWS**) |
| `flask --app run crear-bibliotecario` | Crea un bibliotecario pidiendo los datos por consola (la clave no queda en ningún archivo) |
| `flask --app run db migrate -m "..."` + `db upgrade` | Solo si **cambian los modelos** (¡y primero la planilla!) |

> 🔐 Los bibliotecarios **solo** se crean así. El registro público (`E01`) siempre crea socios: si no, cualquiera se haría bibliotecario. Sería muy chanta.

### 5️⃣ ¡A correr! 🏃

```bash
python run.py
```

| URL | Qué hay |
|---|---|
| http://127.0.0.1:5000/docs | 📘 **Swagger**: prueba todos los endpoints con el botón **Authorize** |
| http://127.0.0.1:5000/openapi.json | La especificación en crudo |

> 📱 **Pa' probar desde un celular físico** (en la misma wifi): en el `.env` pon `HOST=0.0.0.0`, vuelve a correr `python run.py`, y en la app usa la IP de tu compu (ej. `http://192.168.1.50:5000`). Si Windows pregunta por el firewall, dale permiso a Python en redes privadas.

---

## 📱 Levantar la app Flutter

### ✅ Lo que necesitas

- **Flutter 3.x** (canal stable) → revisa con `flutter doctor` que todo salga ✅
- **Android Studio** con un emulador creado (o tu celular con depuración USB)

### 1️⃣ Completar el proyecto Android (solo la primera vez)

El repo trae **todo el código** de la app (`lib/`, `test/`, `pubspec.yaml`) y el `AndroidManifest.xml` ya configurado. Lo que falta (Gradle, íconos, `MainActivity`) lo genera Flutter **con tu versión**, así no hay peleas de versiones:

```bash
cd app_movil
flutter create --org cl.biblioteca --project-name biblioteca_app --platforms android .
flutter pub get
```

> 🧠 `flutter create .` sobre un proyecto existente **solo agrega lo que falta**: no pisa `lib/`, `pubspec.yaml` ni el manifest. Si por alguna razón el manifest quedó sin el permiso de internet, revisa el paso 2.

### 2️⃣ Permisos de Android 🤖 (ya vienen listos)

En `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Sin esto, el APK release NO tiene internet (en debug sí, y por eso engaña 👀) -->
<uses-permission android:name="android.permission.INTERNET"/>

<application
    android:label="Biblioteca"
    android:usesCleartextTraffic="true"
    ...>
```

> ⚠️ `usesCleartextTraffic="true"` permite `http://` (sin la S). Android lo bloquea por defecto desde la versión 9. Úsalo **solo mientras no haya HTTPS**: cuando la API en AWS tenga dominio y certificado, cámbialo a `false`.

### 3️⃣ ¡A correr! La URL de la API nunca va a mano en el código

```dart
// lib/config/api_config.dart
static const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:5000', // 👈 el "localhost" de tu compu visto desde el emulador
);
```

```bash
flutter run                                                   # emulador → usa 10.0.2.2
flutter run --dart-define=API_URL=http://192.168.1.50:5000    # celular físico en tu wifi
```

> 🤯 **El clásico:** desde el emulador, `localhost` es **el emulador**, no tu compu. Por eso se usa `10.0.2.2`. Te ahorré media tarde, de nada 😎.

### 4️⃣ Cómo debe reaccionar la app a cada respuesta

| La API responde | La app hace |
|---|---|
| ✅ 200 / 🆕 201 / 🗑️ 204 | Muestra el resultado |
| 📝 **400** | Muestra el mensaje de `detalles` debajo de cada campo del formulario |
| 🤷 **401** | Borra el token guardado y manda al **login** |
| 🚫 **403** | Muestra "no tienes permiso" (y **NO** manda al login) |
| 🔍 **404** | "No encontrado" y vuelve atrás |
| 💥 **409** | Muestra un mensaje según el `motivo` (ej. `LIMITE_PRESTAMOS` → "Este socio ya tiene 3 libros prestados") |

El token se guarda con `flutter_secure_storage` y se manda en **cada** petición protegida:

```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
}
```

Al abrir la app, se llama a `GET /api/auth/yo`: si responde 200, según el `rol` se muestra el menú de **socio** o el **panel del bibliotecario**; si responde 401, al login. Todo eso vive en `lib/core/api_client.dart` y `lib/providers/sesion.dart`.

### 5️⃣ Qué ve cada uno

| Pantalla | 🌍 Anónimo | 🙋 Socio | 👩‍💼 Bibliotecario |
|---|---|---|---|
| Login / Hazte socio (E02 / E01) | ✅ | | |
| Catálogo con búsqueda y filtros (E04, E10) | | ✅ | ✅ + crear libro y categoría (E06, E11) |
| Detalle del libro (E05) | | ✅ ve si hay copias | ✅ + editar, borrar, agregar copia y **prestar tocando una copia** (E07, E08, E09, E12) |
| Mis préstamos (E15) | | ✅ cupos, vencimientos y multas | |
| Préstamos (E13) | | | ✅ filtros, **devolver** (E14) y **cobrar multa** (E16) |
| Perfil (E03) | | ✅ su **número de socio** | ✅ |

### 6️⃣ Pruebas de la app

```bash
flutter analyze          # 0 problemas esperados
flutter test             # modelos (JSON del contrato), formatos, validaciones y widgets

# Opcional: la app contra tu API corriendo de verdad (con datos de init-db)
flutter test test/api_contrato_test.dart --dart-define=API_URL=http://127.0.0.1:5000
```

---

## 🔌 Endpoints

Todo el detalle (entradas, validaciones, respuestas, ejemplos JSON) está en la **planilla** y en la **guía** de `docs/`. Acá va el resumen pa' tenerlo a mano:

| ID | Método | Ruta | Quién | Pa' qué |
|---|---|---|---|---|
| E01 | `POST` | `/api/auth/registro` | 🌍 cualquiera | Crear cuenta de socio |
| E02 | `POST` | `/api/auth/login` | 🌍 cualquiera | Obtener el token (dura 1 hora) |
| E03 | `GET` | `/api/auth/yo` | 🔑 con token | ¿Quién soy? ¿Qué rol tengo? |
| E04 | `GET` | `/api/libros` | 🔑 con token | Catálogo: `?buscar=` `?categoria=` `?disponible=` `?pagina=` `?tam=` |
| E05 | `GET` | `/api/libros/{id}` | 🔑 con token | Detalle de un libro + estado de sus copias |
| E06 | `POST` | `/api/libros` | 👩‍💼 bibliotecario | Agregar libro |
| E07 | `PUT` | `/api/libros/{id}` | 👩‍💼 bibliotecario | Reemplazar libro (todos los campos) |
| E08 | `DELETE` | `/api/libros/{id}` | 👩‍💼 bibliotecario | Borrar libro (si nunca se ha prestado) |
| E09 | `POST` | `/api/libros/{id}/copias` | 👩‍💼 bibliotecario | Agregar una copia física |
| E10 | `GET` | `/api/categorias` | 🔑 con token | Listar categorías |
| E11 | `POST` | `/api/categorias` | 👩‍💼 bibliotecario | Crear categoría |
| E12 | `POST` | `/api/prestamos` | 👩‍💼 bibliotecario | Registrar préstamo |
| E13 | `GET` | `/api/prestamos` | 👩‍💼 bibliotecario | Ver préstamos de todos (`?socio_id=` `?estado=` `?atrasado=` `?multa=`) |
| E14 | `POST` | `/api/prestamos/{id}/devolucion` | 👩‍💼 bibliotecario | Registrar devolución (y multa si hay atraso) |
| E15 | `GET` | `/api/mis-prestamos` | 🙋 el socio dueño | Ver **mis** préstamos y mis multas |
| E16 | `POST` | `/api/multas/{id}/pago` | 👩‍💼 bibliotecario | Registrar pago de multa |

---

## 🔐 Seguridad: quién puede hacer qué

|  | 🌍 Anónimo | 🙋 Socio | 👩‍💼 Bibliotecario |
|---|---|---|---|
| Registro y login (E01, E02) | ✅ | ✅ | ✅ |
| Catálogo, categorías, "yo" (E03, E04, E05, E10) | ❌ 401 | ✅ | ✅ |
| Mis préstamos (E15) | ❌ 401 | ✅ solo los suyos | ✅ (lista vacía, no tiene préstamos) |
| Gestión: libros, copias, categorías, préstamos, devoluciones, multas | ❌ 401 | ❌ **403** | ✅ |

**Lo que hay que tener siempre en la cabeza:**

- 🤷 **401** = *"no sé quién eres"* (no hay token, es falso o expiró) → al login.
- 🚫 **403** = *"sé quién eres, pero esto no te toca"* → mensaje de "sin permiso".
- 🔐 **Nadie ve préstamos ajenos:** `/api/mis-prestamos` no tiene id en la ruta (no hay número que cambiar), y la lista de todos (`/api/prestamos`) es solo del bibliotecario.
- 🙅 El cliente **nunca** manda `id`, `rol`, fechas ni estados: si vienen en el cuerpo → **400**.
- 🧂 Las claves se guardan como **hash**. Nunca en texto plano, nunca en una respuesta, nunca dentro del token.

---

## 🧯 Errores: cómo responde la API cuando algo falla

Siempre con la misma forma, pa' que la app tenga **un solo** manejador de errores:

```json
{ "error": "Mensaje legible", "codigo": 404 }
```

```json
{ "error": "Datos inválidos en: isbn", "codigo": 400, "detalles": { "isbn": ["10 o 13 dígitos, sin guiones."] } }
```

```json
{ "error": "El socio ya tiene 3 préstamos activos", "codigo": 409, "motivo": "LIMITE_PRESTAMOS" }
```

| `motivo` (solo en 409) | Cuándo pasa |
|---|---|
| `USUARIO_DUPLICADO` | El RUT o el email ya están registrados |
| `ISBN_DUPLICADO` | Otro libro ya tiene ese ISBN |
| `LIBRO_CON_PRESTAMOS` | Se quiere borrar un libro que ya se ha prestado |
| `CODIGO_DUPLICADO` | Ya existe una copia con ese código de inventario |
| `CATEGORIA_DUPLICADA` | Ya hay una categoría con ese nombre |
| `LIMITE_PRESTAMOS` | El socio ya tiene 3 préstamos activos |
| `COPIA_NO_DISPONIBLE` | La copia ya está prestada |
| `PRESTAMO_YA_DEVUELTO` | Se intentó devolver dos veces |
| `MULTA_YA_PAGADA` | Se intentó pagar dos veces |

**Orden en que se revisa todo** (si hay varios problemas, gana el primero):
`401` → `403` → `400` (formato) → `404` (id de la ruta) → `400` (ids del cuerpo) → `409` (reglas) → ✅

**Fechas:** `"2026-10-27"` (fecha) y `"2026-10-13T10:30:00"` (fecha y hora, hora de Chile).

---

## 🧪 Pruebas

**Una prueba automática por cada fila de la hoja 4-Salidas** (las 68 respuestas). La última prueba revisa que no falte ninguna: si alguien agrega un endpoint a la planilla y no lo prueba, falla. 🏆

```bash
cd backend
pip install -r requirements-dev.txt
pytest -v                     # SQLite en memoria: rápido, sin MySQL
```

Antes de entregar o de subir a AWS, córranlas **contra MySQL** (ahí las mayúsculas y los tildes se comparan distinto):

```bash
# en el .env:  TEST_DATABASE_URL=mysql+pymysql://biblio_app:cambia-esta-clave@localhost:3306/biblioteca_test?charset=utf8mb4
pytest -v                     # ⚠️ la base biblioteca_test se BORRA en cada corrida
```

Lo que ya se verificó al construirlo ✅:

| Qué | Resultado |
|---|---|
| `pytest` con SQLite y con **MySQL 8.0** (servidor en UTC, como AWS) | 19 pruebas OK, 68/68 filas del contrato |
| **Gunicorn (4 workers) + Nginx + MySQL**, como quedará en AWS | Responde igual que en local |
| 8 préstamos **simultáneos** de la misma copia | 1 × 201 y 7 × 409 `COPIA_NO_DISPONIBLE` |
| 6 préstamos **simultáneos** al mismo socio | Nunca pasa de 3 activos (409 `LIMITE_PRESTAMOS`) |
| Buscar `garcia` en MySQL | Encuentra a **García** ✨ |
| App Flutter: análisis estático (Flutter stable + `flutter_lints`) | 0 problemas |
| El código de la app (cliente, servicios y modelos) contra la API real | 29/29 chequeos de punta a punta ✅ |

> 🙋 Lo que **no** se pudo probar desde acá: correr la app en un emulador o celular. Eso les toca a ustedes con `flutter run` (y contarme si algo se ve raro).

Pa' probar a mano, sigan el **plan de pruebas paso a paso** de la guía (`docs/Guia_Estudio_API.md`, sección 10): registro → login → libro → copias → 3 préstamos → el 4.º da 409 → devolución con multa → pago.

---

## ☁️ Rumbo a AWS

Todavía no está arriba, pero el proyecto **ya está armado pensando en la nube**, pa' que el día del deploy no sea un parto 😅. El paso a paso completo (qué elegir en cada pantalla de la consola) está en **[`deploy/aws/README.md`](deploy/aws/README.md)**, y el script `deploy/aws/instalar_en_ec2.sh` hace casi todo solo.

### ✅ Lo que ya dejamos listo desde el día 1

| Decisión | Por qué importa en AWS |
|---|---|
| 🔧 **Toda la config sale de variables de entorno** (`DATABASE_URL`, `JWT_SECRET_KEY`…) | En el servidor solo cambian las variables; el código es el mismo |
| 🙅 **Cero secretos en git** (`.env` en `.gitignore`, solo se sube `.env.example`) | Si una clave de AWS o de la BD llega a GitHub, la roban en minutos |
| 🗃️ **Migraciones** con Flask-Migrate (no `create_all`) | Pa' crear y actualizar las tablas en RDS sin borrar datos |
| 🦄 **Gunicorn** en `requirements.txt` | `python run.py` es solo pa' desarrollo |
| 🕐 **Zona horaria explícita** (`ZONA_HORARIA=America/Santiago`) | Los servidores de AWS andan en **UTC**: sin esto, los vencimientos y las multas se calculan con 3 horas de diferencia ⏰ |
| 🔐 **API sin estado** (JWT, sin sesiones) | Se pueden poner varias instancias detrás de un balanceador sin cambiar nada |
| 📱 **URL de la API por `--dart-define`** | El mismo código apunta a local o a AWS sin tocar nada |

> 💡 **La zona horaria ya está resuelta en el código:** `backend/app/tiempo.py` tiene `ahora()` y `hoy()`, que siempre devuelven la hora de Chile (o la de `ZONA_HORARIA`). Ningún archivo usa `datetime.now()` a secas.

### 🗺️ El plan de deploy (opción recomendada: EC2 + RDS)

1. 🐬 **Amazon RDS (MySQL 8)**: instancia chica de la capa gratuita, **sin acceso público**. Su *security group* solo deja entrar al puerto `3306` desde el *security group* del EC2.
2. 🖥️ **EC2** (Ubuntu 24.04 LTS): *security group* con `22` (SSH, **solo desde tu IP**), `80` y `443` abiertos.
3. 📌 **Elastic IP** al EC2, pa' que la dirección no cambie cada vez que se reinicia (si cambia, la app queda apuntando a la nada).
4. 🔧 En el EC2: clonar el repo y correr `bash deploy/aws/instalar_en_ec2.sh` (instala Python, Nginx, el `venv`, las dependencias, pone la hora de Chile y deja todo como servicio). Las variables van en `backend/.env` del servidor, con `DATABASE_URL` apuntando al endpoint de RDS.
5. 🗃️ El script corre `flask --app run init-db --sin-datos` (solo tablas) y después creas el primer bibliotecario con `flask --app run crear-bibliotecario`.
6. 🦄 Gunicorn como servicio de `systemd` (`deploy/aws/biblioteca-api.service`): se levanta solo si el EC2 se reinicia.
7. 🌐 **Nginx** adelante (`deploy/aws/nginx-biblioteca.conf`), como proxy hacia `127.0.0.1:8000`.
8. 🔒 **HTTPS**: con un dominio (ej. `api.biblioteca.cl`) y un certificado gratis de Let's Encrypt (`certbot`). Ojo: para HTTPS de verdad **se necesita un dominio**; con la pura IP no se puede.
9. 📦 Compilar el APK apuntando a AWS:
   ```bash
   flutter build apk --release --dart-define=API_URL=https://api.biblioteca.cl
   ```

**Plan B 🅱️:** Elastic Beanstalk (plataforma Python) + RDS. Hace varios de esos pasos por uno, pero esconde más cosas. Pa' aprender, EC2 enseña harto más.

### 💸 Ojo con la billetera

- Configuren un **AWS Budget** con alerta (ej. USD 5) **antes** de crear cualquier cosa.
- Usen las instancias de la **capa gratuita** y apáguenlas cuando no estén probando.
- Si usan **AWS Academy (Learner Lab)**, revisen las reglas del lab: la sesión expira y los recursos se pueden detener; por eso lo de la Elastic IP es clave.

---

## 🗺️ Roadmap

- [x] 📜 Contrato de la API (planilla) — 13 de 13 contadores en OK
- [x] 📘 Guía de estudio del contrato
- [x] 🗃️ Backend: modelos + migraciones en MySQL
- [x] 🔑 Backend: autenticación (E01–E03)
- [x] 📚 Backend: catálogo, copias y categorías (E04–E11)
- [x] 🔄 Backend: préstamos, devoluciones y multas (E12–E16)
- [x] 🧪 Pruebas automáticas de las 68 respuestas
- [x] 📱 App: login y registro
- [x] 📱 App: catálogo y detalle de libro
- [x] 📱 App: mis préstamos (y mis multas)
- [x] 📱 App: panel del bibliotecario (préstamo, devolución, pago)
- [ ] 📲 Probar la app en el emulador y en un celular de verdad
- [ ] ☁️ Deploy en AWS (EC2 + RDS + HTTPS) → `deploy/aws/README.md`
- [ ] 📦 APK release apuntando a AWS

---

## 🤝 Cómo trabajamos (git)

- 🌱 `main` siempre funciona. Cada cosa nueva va en su rama: `feat/prestamos`, `fix/multa-zona-horaria`, `app/login`…
- ✍️ Commits cortos y en español, que digan qué cambió: `feat(prestamos): E12 con regla de 3 activos`.
- 📜 **¿Hay que cambiar un endpoint?** Primero se actualiza la planilla, se avisa al compañero, y recién ahí se toca el código.
- 🔍 Antes de juntar a `main`: las pruebas pasan y Swagger muestra lo mismo que dice la planilla.
- 🙅 Nunca se suben: `.env`, `venv/`, `__pycache__/`, `build/`, `*.apk`, ni claves de AWS.

---

## 👥 Equipo

| | Integrante |
|---|---|
| 🧑‍💻 | **Donovan Sepúlveda** |
| 🧑‍💻 | **Carlos Urdaneta** |

📖 Proyecto del ramo **Desarrollo Web y Aplicaciones Móviles** · Caso 1: Biblioteca Comunitaria.

---

<p align="center">
  Hecho con 💙, ☕ y harta paciencia en 🇨🇱<br>
  <i>Si algo no funciona, revisa primero el .env. Casi siempre es el .env.</i> 😅
</p>
