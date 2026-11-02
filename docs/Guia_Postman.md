<h1 align="center">📮 Guía Postman</h1>

<p align="center">
  <b>Qué quiere el profe, qué es una API, cómo funciona nuestro código<br>y cómo ingresar y listar datos con Postman</b><br>
  <i>Pa' gente que no sabe nada de APIs (todavía) 😎</i>
</p>

---

## 🗺️ Índice

0. [La respuesta corta](#-0-la-respuesta-corta)
1. [¿Qué quiere el profe?](#-1-qué-quiere-el-profe)
2. [APIs desde cero](#-2-apis-desde-cero)
3. [Nuestro proyecto en un dibujo](#️-3-nuestro-proyecto-en-un-dibujo)
4. [Recorrido por nuestro código](#-4-recorrido-por-nuestro-código)
5. [Antes de abrir Postman: levantar la API](#-5-antes-de-abrir-postman-levantar-la-api)
6. [Postman paso a paso](#-6-postman-paso-a-paso)
7. [Recetario: ingresar datos (POST)](#-7-recetario-ingresar-datos-post)
8. [Recetario: listar datos (GET)](#-8-recetario-listar-datos-get)
9. [Bonus: modificar y borrar (PUT y DELETE)](#️-9-bonus-modificar-y-borrar-put-y-delete)
10. [Errores que lucen](#-10-errores-que-lucen)
11. [Devolución y multa](#-11-devolución-y-multa)
12. [Cómo entregar la evidencia](#-12-cómo-entregar-la-evidencia)
13. [Si algo falla](#-13-si-algo-falla)
14. [Glosario express](#-14-glosario-express)

---

## ⚡ 0. La respuesta corta

> 🗣️ **"Ingresar / listar datos con Postman"** = usar Postman (un programa) para **mandarle peticiones a nuestra API**, sin la app: **crear** registros nuevos en la base de datos (*ingresar* 👉 `POST`) y **verlos** (*listar* 👉 `GET`).

Lo que hay que hacer, en 6 pasos:

1. 🐬 Tener MySQL corriendo.
2. 🐍 Levantar la API: `flask --app run init-db` y `python run.py` (carpeta `backend/`).
3. 📮 Abrir **Postman** (la app de escritorio).
4. 📥 **Importar** nuestra colección: `postman/Biblioteca_Comunitaria.postman_collection.json`.
5. ▶️ Correrla con el botón **Run**: son **34 peticiones** que ingresan, listan, modifican, borran y prueban errores.
6. 📸 Sacar capturas pa' la entrega (sección 12).

Y si el profe quiere verte hacerlo **a mano**, la sección 6.4 te explica cómo, paso a paso. 🙌

---

## 🤔 1. ¿Qué quiere el profe?

Hasta ahora la API la hemos usado desde la app o desde Swagger. El profe quiere ver que **ustedes saben hablarle a la API directamente**, con la herramienta que se usa en la pega de verdad: **Postman**.

| Lo que dice el profe | Lo que significa | Método HTTP | Ejemplo en nuestra API |
|---|---|---|---|
| **Ingresar** datos | Crear cosas nuevas en la base de datos | `POST` | Crear una categoría, un libro, una copia, un préstamo |
| **Listar** datos | Ver lo que hay guardado | `GET` | Ver el catálogo, las categorías, los préstamos |

Lo más probable es que quiera ver:

- ✅ Que **ingresas** un dato (ej. un libro) y la API responde **201 Created**.
- ✅ Que después lo **listas** y el dato nuevo **aparece**.
- ✅ Que entiendes el **token**: sin token la API responde **401**.

> 🙋 **Ojo:** la instrucción no dice *cómo* entregarlo (capturas, exportar la colección o mostrarlo en vivo). Si no está claro, pregúntenle al profe. Igual en la sección 12 dejé las tres opciones listas.

---

## 🧠 2. APIs desde cero

### 2.1 🍽️ La analogía del restaurante

```
   👤 TÚ                    🧑‍🍳 GARZÓN                     🍳 COCINA
 (Postman o la app)   ──▶   (la API Flask)         ──▶   (la base MySQL)
 "Quiero el libro 1"        revisa que puedas pedir,      tiene los datos
                            va a buscarlo y te lo trae
                     ◀──    "Aquí está (200)"        ◀──
```

- **Tú** nunca entras a la cocina. Siempre le pides al **garzón**.
- El garzón tiene **reglas**: no te trae nada si no tienes **pulsera** (token), y hay platos que solo pide el personal (bibliotecario).
- La **carta** es nuestra **planilla** (el contrato): dice qué se puede pedir y cómo.

**Postman** es simplemente una forma de hablar con el garzón **sin tener la app**. Escribes la petición a mano, la mandas y ves la respuesta. Así de simple. 🙌

### 2.2 📤 Las partes de una petición (lo que MANDAS)

| Parte | Qué es | Ejemplo |
|---|---|---|
| **Método** | El verbo: qué quieres hacer | `GET` (ver), `POST` (crear), `PUT` (reemplazar), `DELETE` (borrar) |
| **URL** | Dónde está la cosa | `http://127.0.0.1:5000/api/libros` |
| **Params** | Filtros que van en la URL, después del `?` | `?buscar=soledad&pagina=1` |
| **Headers** (cabeceras) | Datos extra, como el token | `Authorization: Bearer eyJhbGci...` |
| **Body** (cuerpo) | Los datos que mandas, en JSON. Solo en `POST` y `PUT` | `{ "nombre": "Cómics" }` |

### 2.3 📥 Las partes de una respuesta (lo que te DEVUELVEN)

| Parte | Qué es | Ejemplo |
|---|---|---|
| **Código de estado** | Un número que dice cómo salió | `200`, `201`, `401`… |
| **Body** | Los datos, en JSON | `{ "id": 9, "nombre": "Cómics", "total_libros": 0 }` |

Los códigos que vas a ver:

| Código | Emoji | Significa |
|---|---|---|
| **200** OK | ✅ | Salió bien, aquí están los datos |
| **201** Created | 🆕 | Salió bien y **se creó** algo nuevo (típico de *ingresar*) |
| **204** No Content | 🗑️ | Salió bien y no hay nada que mostrar (típico de borrar) |
| **400** Bad Request | 📝 | Mandaste algo mal (falta un campo, formato malo) |
| **401** Unauthorized | 🤷 | **No sé quién eres**: falta el token, está malo o venció |
| **403** Forbidden | 🚫 | **Sé quién eres, pero esto no te toca** (eres socio, no bibliotecario) |
| **404** Not Found | 🔍 | No existe (ej. el libro 999999) |
| **409** Conflict | 💥 | Los datos están bien, pero **chocan** con lo que ya hay (ej. copia ya prestada) |

> 💡 Regla fácil: los **2xx** son buenas noticias, los **4xx** son "te equivocaste tú", y los **5xx** son "se cayó el servidor" (si ves un 500, avísanos).

### 2.4 🧾 JSON en un minuto

JSON es el "idioma" en que se mandan los datos. Son pares **"nombre": valor**, entre llaves:

```json
{
  "titulo": "La amortajada",
  "anio_publicacion": 1938,
  "disponible": true,
  "categoria": { "id": 1, "nombre": "Novela" },
  "copias": [ { "id": 1 }, { "id": 2 } ]
}
```

| Cosa | Cómo se escribe |
|---|---|
| Texto | entre comillas **dobles**: `"La amortajada"` |
| Número | sin comillas: `1938` |
| Verdadero / falso | `true` / `false` (sin comillas) |
| Nada | `null` |
| Objeto (una cosa con partes) | `{ ... }` |
| Lista | `[ ... ]` |

> ⚠️ Errores típicos: comillas simples `'así'` ❌, coma después del último dato `{"a": 1,}` ❌.

### 2.5 🎫 El token, explicado con un recital

1. En la entrada muestras tu carnet (**correo + clave**) → te ponen una **pulsera** (**token**). Eso es el **login**.
2. Pa' entrar a cualquier zona, muestras la pulsera, no el carnet. En la API, la pulsera va en la cabecera: `Authorization: Bearer <token>`.
3. La pulsera dice si eres **socio** o **bibliotecario** (el rol va dentro del token).
4. La pulsera **dura 1 hora**. Después hay que hacer login de nuevo (si no, 401).

### 2.6 🔗 Si ya sabes SQL, esto te va a sonar

| Postman (HTTP) | CRUD | SQL que hace la API por dentro |
|---|---|---|
| `POST /api/libros` | **C**reate (crear) | `INSERT INTO libro ...` |
| `GET /api/libros` | **R**ead (leer) | `SELECT * FROM libro ...` |
| `PUT /api/libros/12` | **U**pdate (actualizar) | `UPDATE libro SET ... WHERE id = 12` |
| `DELETE /api/libros/12` | **D**elete (borrar) | `DELETE FROM libro WHERE id = 12` |

La diferencia: tú **no escribes SQL**. La API lo escribe por ti, y **antes revisa las reglas** (token, rol, datos válidos, máximo 3 préstamos…). Por eso existe la API: pa' que nadie le hable directo a la base. 🔐

---

## 🏗️ 3. Nuestro proyecto en un dibujo

```
 ┌───────────────┐
 │ 📮 Postman     │ ──┐
 └───────────────┘   │   HTTP + JSON          ┌──────────────────────────┐   SQL    ┌──────────────┐
                     ├──────────────────────▶ │ 🐍 API Flask              │ ───────▶ │ 🐬 MySQL      │
 ┌───────────────┐   │   (con el token)       │  carpeta backend/        │          │  base         │
 │ 📱 App Flutter │ ──┘ ◀──────────────────── │  http://127.0.0.1:5000   │ ◀─────── │  "biblioteca" │
 └───────────────┘        respuesta JSON      └──────────────────────────┘          └──────────────┘
```

**Postman y la app hacen exactamente lo mismo:** mandan peticiones a la API. La app lo hace con botones bonitos; Postman lo hace "a mano". Por eso, si algo funciona en Postman, también funciona en la app (y al revés). 🤝

---

## 🐍 4. Recorrido por nuestro código

### 4.1 🗂️ Qué hace cada archivo de `backend/`

| Archivo | Qué hace (en simple) | En el restaurante sería… |
|---|---|---|
| `run.py` | Prende la API | Abrir el local |
| `app/__init__.py` | Arma la API: junta todas las piezas | El encargado que organiza todo |
| `app/config.py` | Lee el `.env` (clave de la base, clave del token, reglas) | El cuaderno con las claves |
| `app/rutas/*.py` | **Los 16 endpoints**: qué pasa con cada petición | Los garzones, uno por sección |
| `app/seguridad.py` | Revisa el token y el rol (401 / 403) | El guardia de la puerta |
| `app/esquemas.py` | Revisa que los datos que llegan estén bien (400) y arma el JSON de respuesta | El que revisa que el pedido esté bien escrito |
| `app/modelos.py` | Las tablas de la base, en Python | El inventario de la cocina |
| `app/errores.py` | Que todos los errores tengan el mismo formato | El libro de reclamos (todos iguales) |
| `app/tiempo.py` | La hora de Chile (pa' vencimientos y multas) | El reloj de la pared |
| `app/comandos.py` | `flask init-db`: crea tablas y datos de prueba | Surtir la cocina antes de abrir |
| `migrations/` | La "receta" para crear las tablas en MySQL | Los planos de la cocina |
| `tests/` | Pruebas automáticas de las 68 respuestas del contrato | El inspector que prueba todo |

Y dentro de `app/rutas/`, cada archivo atiende unos endpoints:

| Archivo | Endpoints | Qué cubre |
|---|---|---|
| `auth.py` | E01 · E02 · E03 | Registro, login, "¿quién soy?" |
| `libros.py` | E04 al E09 | Catálogo, detalle, crear, editar, borrar, agregar copia |
| `categorias.py` | E10 · E11 | Listar y crear categorías |
| `prestamos.py` | E12 · E13 · E14 | Prestar, listar préstamos, devolver |
| `mis_prestamos.py` | E15 | Los préstamos del socio que inició sesión |
| `multas.py` | E16 | Pagar una multa |

### 4.2 🚶 El viaje de una petición (de Postman a MySQL y de vuelta)

Cuando en Postman mandas **`POST /api/prestamos`** con `{"socio_id": 2, "copia_id": 5}`, pasa esto en `app/rutas/prestamos.py`:

```python
@bibliotecario_requerido                                     # ① ¿Tiene pulsera? ¿Es bibliotecario?  (401 / 403)
@blp.arguments(PrestamoEntradaSchema, error_status_code=400) # ② ¿Los datos vienen bien?             (400)
@blp.response(201, PrestamoSchema)                           # ⑦ La respuesta sale con este formato   (201)
def post(self, datos):
    socio = ...buscar el socio...                            # ③ ¿Existe el socio? ¿Está activo?      (400)
    copia = ...buscar la copia...                            # ④ ¿Existe la copia?                     (400)
    if activos >= maximo:                                    # ⑤ ¿Ya tiene 3 préstamos?                (409)
        abort(409, ..., motivo="LIMITE_PRESTAMOS")
    ...si la copia no está disponible...                     # ⑥ ¿La copia está libre?                 (409)
        abort(409, ..., motivo="COPIA_NO_DISPONIBLE")
    prestamo = Prestamo(..., fecha_vencimiento=hoy + 14 días)   # el servidor calcula las fechas
    copia.estado = "prestada"
    db.session.commit()                                      # 💾 se guarda en MySQL (INSERT + UPDATE)
    return prestamo                                          # → 201 + el préstamo en JSON
```

Lo bacán: **cada `if` es una regla de la planilla**. Si una regla falla, la función se corta ahí mismo (`abort`) y Postman recibe el código de error. Si todo pasa, se guarda y responde **201**. 🎯

> 🔐 Fíjate que el socio **nunca** manda las fechas ni el estado: los pone el servidor. Si los mandas igual, la API responde **400** ("Campo no permitido").

### 4.3 👀 Un GET es mucho más corto

`GET /api/libros/1` (en `app/rutas/libros.py`):

```python
@jwt_required()                          # ¿tiene token? (si no, 401)
@blp.response(200, LibroDetalleSchema)   # la respuesta sale con este formato
def get(self, libro_id):
    return libro_o_404(libro_id)         # SELECT ... WHERE id = 1   (si no existe, 404)
```

### 4.4 🧭 ¿Dónde busco si algo raro pasa?

| Ves esto en Postman | Busca en |
|---|---|
| 401 en todo | `app/seguridad.py` y `app/__init__.py` (el token) |
| 403 | `app/seguridad.py` (`@bibliotecario_requerido`) |
| 400 con `detalles` | `app/esquemas.py` (las validaciones de cada campo) |
| 409 con `motivo` | el archivo de `app/rutas/` de ese endpoint (las reglas) |
| 500 | la terminal donde corre `python run.py`: ahí sale el error completo |

---

## 🚀 5. Antes de abrir Postman: levantar la API

Postman le habla a la API, así que **la API tiene que estar prendida**. En una terminal (en VS Code: *Terminal → New Terminal*):

```bash
cd backend
venv\Scripts\activate          # 🪟 Windows (si tu venv está en la raíz: .venv\Scripts\activate)
flask --app run init-db        # crea las tablas y carga datos de prueba (se puede repetir)
python run.py                  # ¡prende la API!
```

Tiene que decir algo como `Running on http://127.0.0.1:5000`. **No cierres esa terminal** mientras uses Postman. 🚨

✅ **Prueba rápida:** abre en el navegador `http://127.0.0.1:5000/docs`. Si ves el Swagger, la API está viva.

Usuarios que deja `init-db`:

| Quién | Correo | Clave |
|---|---|---|
| 👩‍💼 Bibliotecaria | `biblio@biblioteca.cl` | `biblio1234` |
| 🙋 Socia | `ana.rojas@correo.cl` | `clave-segura-123` |
| 🙋 Socio | `pedro.soto@correo.cl` | `clave-segura-123` |

---

## 📮 6. Postman paso a paso

### 6.1 💾 Instalar

1. Descarga **Postman** desde [postman.com/downloads](https://www.postman.com/downloads/) (la app de **escritorio**).
2. Crea una cuenta gratis e inicia sesión. Sin cuenta, Postman puede dejarte solo en modo de peticiones sueltas, sin colecciones.

> ⚠️ Usa la **app de escritorio**, no Postman en el navegador: la versión web no llega a `127.0.0.1` (tu propio computador) sin instalar un agente aparte.

### 6.2 🖥️ Las partes de la pantalla

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [ POST ▼ ]  {{baseUrl}}/api/categorias                              [ Send ] │ ← ① método + URL
├──────────────────────────────────────────────────────────────────────────────┤
│  Params │ Authorization │ Headers │ Body │ Scripts │ Settings                │ ← ② lo que MANDAS
│                                                                              │
│  Body:  ( ) none  ( ) form-data  (•) raw   [ JSON ▼ ]                        │
│  {                                                                           │
│    "nombre": "Cómics"                                                        │
│  }                                                                           │
├──────────────────────────────────────────────────────────────────────────────┤
│  Status: 201 CREATED    Time: 12 ms                                          │ ← ③ lo que RESPONDE
│  { "id": 9, "nombre": "Cómics", "total_libros": 0 }                          │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Zona | Pa' qué |
|---|---|
| ① Método + URL | Qué haces y dónde |
| **Params** | Filtros del `?` (ej. `buscar`, `pagina`) |
| **Authorization** | El token (elige **Bearer Token**) |
| **Body** | Los datos que mandas (**raw** + **JSON**) |
| **Scripts** | Código que corre antes (*Pre-request*) o después (*Post-response*) de mandar. Nuestra colección lo usa pa' guardar el token sola |
| ③ Respuesta | El código (201, 404…) y el JSON que devolvió la API |

### 6.3 🎁 Opción A: importar nuestra colección (lo más rápido)

Una **colección** es una carpeta de peticiones ya armadas. Te dejé una con **las 34 peticiones**, que cubren los 16 endpoints:

1. En Postman: botón **Import** (arriba a la izquierda).
2. Arrastra el archivo `postman/Biblioteca_Comunitaria.postman_collection.json`.
3. Aparece **📚 API Biblioteca Comunitaria** con 6 carpetas:

| Carpeta | Qué hace | Peticiones |
|---|---|---|
| 1 · 🔑 Autenticación | Login de la bibliotecaria, crea un socio nuevo y hace login con él (**guarda los tokens sola**) | 4 |
| 2 · ➕ Ingresar datos | Crea categoría → libro → copia → préstamo | 4 |
| 3 · 📋 Listar datos | Catálogo, búsqueda, filtros, detalle, categorías, préstamos, mis préstamos | 9 |
| 4 · ✏️ Modificar y borrar | Editar libro (PUT), crear y borrar otro libro (DELETE) | 3 |
| 5 · 🚨 Errores | 401, 403, 404, 400 y 409 a propósito | 11 |
| 6 · 🔄 Devolución y multa | Devolver, devolver otra vez (409), pagar multa | 3 |

**Pa' correr todo de una:** pasa el mouse sobre la colección → **⋯** → **Run collection** → **Run**. Al final deberías ver todas las pruebas en verde ✅ (son 68 chequeos).

**Pa' ir de a una:** abre cada petición y aprieta **Send**, en orden. **Siempre parte por la carpeta 1**: ahí se consiguen los tokens.

> 🧠 **¿Qué son esas `{{cosas}}` con llaves dobles?** Son **variables**. `{{baseUrl}}` vale `http://127.0.0.1:5000` y `{{token_biblio}}` guarda el token de la bibliotecaria. Las ves y cambias en la colección → pestaña **Variables**. Cuando la API esté en AWS, solo cambias `baseUrl` y todo sigue funcionando. 🎉
>
> Los ids (`libro_id`, `copia_id`…) y los datos que no se pueden repetir (ISBN, RUT, nombre de la categoría) **se guardan y se inventan solos** con los scripts. Por eso puedes correr la colección las veces que quieras sin que choque.

### 6.4 ✍️ Opción B: hacerlo a mano (pa' aprender y pa' la demo en vivo)

#### Paso 1 · Login (conseguir el token) 🔑

1. **New** → **HTTP Request** (o el **+** de las pestañas).
2. Método **POST**, URL: `http://127.0.0.1:5000/api/auth/login`
3. Pestaña **Body** → **raw** → en el menú de la derecha elige **JSON** (no "Text") y escribe:
   ```json
   {
     "email": "biblio@biblioteca.cl",
     "clave": "biblio1234"
   }
   ```
4. **Send**. Respuesta **200**:
   ```json
   {
     "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2Ui...",
     "token_type": "Bearer",
     "expira_en": 3600,
     "usuario": { "id": 1, "nombre": "Marta Fuentes", "rol": "bibliotecario", ... }
   }
   ```
5. **Copia** el valor de `access_token` (todo, sin las comillas). Esa es tu pulsera 🎫.

#### Paso 2 · Ingresar un dato (POST) ➕

1. Nueva petición: **POST** `http://127.0.0.1:5000/api/categorias`
2. Pestaña **Authorization** → Auth Type: **Bearer Token** → pega el token.
3. Pestaña **Body** → **raw** → **JSON**:
   ```json
   { "nombre": "Cómics" }
   ```
4. **Send** → **201 Created** 🆕
   ```json
   { "id": 9, "nombre": "Cómics", "total_libros": 0 }
   ```
   ¡Acabas de **ingresar** un dato! Quedó guardado en MySQL, en la tabla `categoria`.

#### Paso 3 · Listarlo (GET) 📋

1. Nueva petición: **GET** `http://127.0.0.1:5000/api/categorias`
2. **Authorization** → **Bearer Token** → el mismo token.
3. **Send** → **200 OK**: aparece la lista, **con "Cómics" adentro**. ✅

```json
[
  { "id": 4, "nombre": "Ciencia", "total_libros": 1 },
  { "id": 9, "nombre": "Cómics", "total_libros": 0 },
  { "id": 5, "nombre": "Historia", "total_libros": 0 },
  ...
]
```

#### Paso 4 · Ver que de verdad está en MySQL 🐬 (opcional, pero luce harto)

En MySQL Workbench:

```sql
USE biblioteca;
SELECT * FROM categoria;
```

Ahí está la fila que creaste desde Postman. **Eso es lo que hace una API:** recibió tu JSON, revisó las reglas y escribió en la base por ti. 🙌

---

## ➕ 7. Recetario: ingresar datos (POST)

Todos estos van con **Authorization → Bearer Token** de la **bibliotecaria** (salvo el registro, que es público). Body siempre en **raw → JSON**.

| # | Qué | Método y URL | Body | Responde |
|---|---|---|---|---|
| 1 | Hacerse socio (E01) | `POST /api/auth/registro` (sin token) | `{"nombre": "Socio de Prueba", "rut": "15555555-5", "email": "socio.prueba@correo.cl", "clave": "clave-segura-123"}` | **201** + el usuario con `rol: "socio"` |
| 2 | Crear categoría (E11) | `POST /api/categorias` | `{"nombre": "Cómics"}` | **201** + `{"id", "nombre", "total_libros"}` |
| 3 | Crear libro (E06) | `POST /api/libros` | `{"titulo": "La amortajada", "autor": "María Luisa Bombal", "isbn": "9789561234567", "anio_publicacion": 1938, "categoria_id": 1}` | **201** + el libro (con su `id` nuevo) |
| 4 | Agregar copia (E09) | `POST /api/libros/{id del libro}/copias` | `{"codigo_inventario": "LIB-000100"}` | **201** + la copia, `estado: "disponible"` |
| 5 | Prestar (E12) | `POST /api/prestamos` | `{"socio_id": 2, "copia_id": 4}` | **201** + el préstamo, vence en 14 días |

Ejemplo real de la respuesta de un préstamo:

```json
{
  "id": 4,
  "socio": { "id": 2, "nombre": "Ana Rojas Pérez", "rut": "12345678-5" },
  "copia": { "id": 2, "codigo_inventario": "LIB-000002" },
  "libro": { "id": 1, "titulo": "Cien años de soledad" },
  "fecha_prestamo": "2026-10-28T09:27:13",
  "fecha_vencimiento": "2026-11-11",
  "fecha_devolucion": null,
  "estado": "activo",
  "atrasado": false,
  "dias_atraso": 0,
  "multa": null
}
```

> 📏 **Reglas pa' que no te dé 400:**
> - RUT sin puntos y con guion: `12345678-5` · clave de 8 o más caracteres.
> - ISBN de 10 o 13 dígitos, **sin guiones**.
> - Código de inventario en **MAYÚSCULAS**, números y guion: `LIB-000100`.
> - **Nunca** mandes `id`, `rol`, fechas ni `estado`: los pone el servidor.
>
> 🔁 **Y pa' que no te dé 409:** RUT, correo, ISBN, código de inventario y nombre de categoría **no se pueden repetir**. Si repites uno, la API responde 409 (y eso también sirve pa' mostrarle al profe 😉).

---

## 📋 8. Recetario: listar datos (GET)

Los `GET` **no llevan body**. Los filtros van en la pestaña **Params** (Postman los agrega solo a la URL).

| # | Qué | URL | Token de | Responde |
|---|---|---|---|---|
| 1 | Catálogo (E04) | `GET /api/libros?pagina=1&tam=10` | cualquiera | **200** + página de libros |
| 2 | Buscar (E04) | `GET /api/libros?buscar=soledad` | cualquiera | Busca en título y autor |
| 3 | Solo disponibles (E04) | `GET /api/libros?disponible=true` | cualquiera | Libros con copias libres |
| 4 | Por categoría (E04) | `GET /api/libros?categoria=1` | cualquiera | Libros de esa categoría |
| 5 | Detalle de un libro (E05) | `GET /api/libros/1` | cualquiera | El libro + sus copias |
| 6 | Categorías (E10) | `GET /api/categorias` | cualquiera | Lista con `total_libros` |
| 7 | ¿Quién soy? (E03) | `GET /api/auth/yo` | cualquiera | Tus datos (el `id` es tu número de socio) |
| 8 | Préstamos de todos (E13) | `GET /api/prestamos?estado=activo` | 👩‍💼 bibliotecaria | Filtros: `socio_id`, `estado`, `atrasado`, `multa` |
| 9 | Mis préstamos (E15) | `GET /api/mis-prestamos` | 🙋 socio | **Solo los del dueño del token** |

Así viene el catálogo (paginado):

```json
{
  "total": 11,
  "pagina": 1,
  "tam": 1,
  "paginas": 11,
  "items": [
    {
      "id": 8,
      "titulo": "Breve historia del tiempo",
      "autor": "Stephen Hawking",
      "categoria": { "id": 4, "nombre": "Ciencia" },
      "copias_total": 1,
      "copias_disponibles": 1,
      "disponible": true
    }
  ]
}
```

- `total`: cuántos libros cumplen el filtro. `paginas`: cuántas páginas hay. `items`: los libros de **esta** página.
- `tam` es cuántos por página (máximo **50**; si pides 51 → 400).

> 🔐 **La gracia de `/api/mis-prestamos`:** no lleva ningún id. El servidor saca al socio **del token**. Aunque le agregues `?socio_id=1`, igual te muestra **solo lo tuyo**. Esa es la regla "un socio ve solo SUS préstamos" del caso. Está probado en la carpeta 5 de la colección. 🛡️

---

## ✏️ 9. Bonus: modificar y borrar (PUT y DELETE)

Con esto completas el **CRUD** del libro (Crear, Leer, Actualizar, Borrar):

| Qué | Método y URL | Body | Responde |
|---|---|---|---|
| Editar libro (E07) | `PUT /api/libros/{id}` | **Todos** los campos (`titulo`, `autor`, `isbn`, `anio_publicacion`, `categoria_id`) | **200** + el libro actualizado |
| Borrar libro (E08) | `DELETE /api/libros/{id}` | (sin body) | **204** (sin nada), o **409** si el libro ya se prestó alguna vez |

> 🧠 `PUT` **reemplaza todo**: si no mandas `anio_publicacion`, queda vacío (`null`). Por eso hay que mandar todos los campos, aunque cambies uno solo.

---

## 🚨 10. Errores que lucen

Mostrar que la API **falla bien** suma harto. La carpeta **5 · 🚨 Errores** de la colección trae todos estos:

| Prueba | Qué haces | Responde | Qué demuestra |
|---|---|---|---|
| Sin token | `GET /api/libros` sin Authorization | **401** | No se puede entrar sin pulsera |
| Clave mala | Login con clave incorrecta | **401** "Correo o contraseña incorrectos" | Mismo mensaje si el correo no existe: no revela qué cuentas hay |
| Socio crea libro | `POST /api/libros` con token de socio | **403** | Sabe quién eres, pero no te toca |
| Socio ve todo | `GET /api/prestamos` con token de socio | **403** | Los préstamos ajenos son privados |
| Colarse | `GET /api/mis-prestamos?socio_id=1` con token de socio | **200**, pero solo lo suyo | La regla de pertenencia funciona |
| No existe | `GET /api/libros/999999` | **404** | — |
| Dato malo | `POST /api/categorias` con `{"nombre": "No"}` | **400** + `detalles` | Valida cada campo y dice cuál falló |
| Ponerse rol | Registro con `"rol": "bibliotecario"` | **400** | Nadie se auto-nombra bibliotecario |
| Repetida | Crear dos veces la misma categoría | **409** `CATEGORIA_DUPLICADA` | — |
| Copia ocupada | Prestar una copia que ya está prestada | **409** `COPIA_NO_DISPONIBLE` | La regla del caso |
| Borrar con historial | `DELETE` de un libro que ya se prestó | **409** `LIBRO_CON_PRESTAMOS` | Protege el historial |

Todos los errores tienen la misma forma (así la app los entiende siempre igual):

```json
{ "error": "Datos inválidos en: nombre", "codigo": 400, "detalles": { "nombre": ["Debe tener entre 3 y 60 caracteres."] } }
```

---

## 🔄 11. Devolución y multa

| Qué | Método y URL | Responde |
|---|---|---|
| Devolver (E14) | `POST /api/prestamos/{id}/devolucion` (sin body) | **200** + préstamo `devuelto` (y la `multa` si hubo atraso) |
| Pagar multa (E16) | `POST /api/multas/{id}/pago` (sin body) | **200** + multa `pagada` |

**¿Cómo pruebo una multa si los préstamos vencen en 14 días?** 🤔 Se hace "trampa" en la base: se mueve la fecha de vencimiento al pasado. En MySQL Workbench:

```sql
USE biblioteca;
-- cambia 4 por el id del préstamo que quieres atrasar
UPDATE prestamo SET fecha_vencimiento = DATE_SUB(CURDATE(), INTERVAL 3 DAY) WHERE id = 4;
```

Ahora devuélvelo desde Postman → la respuesta trae `"multa": {"monto": 1500, "dias_atraso": 3, "estado": "pendiente", ...}` (3 días × $500). Copia el `id` de la multa y págala con `POST /api/multas/{id}/pago`. 💸

> 💡 En la colección, la devolución guarda solita el `multa_id`. Si devolviste a tiempo (sin multa), el pago responde 404, porque no hay nada que pagar. Las dos cosas están bien.

---

## 📸 12. Cómo entregar la evidencia

Como la instrucción no dice cómo, aquí van las tres formas típicas. Hagan las que pida el profe (o todas, pa' ir a la segura):

**📷 Capturas** (lo más común). Una por cada una, donde se vea **método + URL + body + código de respuesta**:

- [ ] Login → **200** con el token
- [ ] Crear categoría → **201**
- [ ] Crear libro → **201**
- [ ] Agregar copia → **201**
- [ ] Crear préstamo → **201**
- [ ] Listar libros (aparece el nuevo) → **200**
- [ ] Listar préstamos → **200**
- [ ] Mis préstamos (socio) → **200**
- [ ] Un **401** (sin token) y un **403** (socio intentando algo de bibliotecario)
- [ ] El **Run** de la colección con todo en verde ✅
- [ ] (Extra) El `SELECT * FROM ...` en Workbench mostrando los datos ingresados

**📦 Exportar la colección**: en la colección → **⋯** → **Export** → *Collection v2.1* → se genera un `.json` que el profe puede importar y correr.

**🎤 Demo en vivo**: API prendida + Postman abierto. Muestren: login → POST → GET (aparece) → un error 401/403. Practíquenlo una vez antes. 😉

---

## 🆘 13. Si algo falla

| Síntoma en Postman | Qué pasa | Cómo se arregla |
|---|---|---|
| `Error: connect ECONNREFUSED 127.0.0.1:5000` / *Could not send request* | La API está apagada | `python run.py` en la carpeta `backend/` (y no cierres esa terminal) |
| **401** "Falta el token" | No pusiste el token | **Authorization** → **Bearer Token** → pega el `access_token` |
| **401** "El token no es válido o expiró" | Pasó más de 1 hora, o el token quedó mal copiado | Haz login de nuevo y copia el token completo |
| **400** "Este campo es obligatorio" **pero sí lo mandaste** | El Body está en **Text**, no en **JSON** | Body → raw → en el menú de la derecha elige **JSON** |
| **400** "Campo no permitido en esta petición" | Mandaste un campo que no va (`id`, `rol`, `fecha_...`) o con un nombre mal escrito | Revisa los nombres exactos en la sección 7 |
| **403** | Usaste el token del socio en algo de bibliotecario | Usa el token de `biblio@biblioteca.cl` |
| **404** en una ruta que debería existir | URL mal escrita (ej. `/api/libro` en vez de `/api/libros`) o el id no existe | Copia la URL de la sección 7 u 8 |
| **409** `LIMITE_PRESTAMOS` | Ese socio ya tiene 3 préstamos activos | Devuelve uno, o usa otro socio |
| **500** | Se cayó algo dentro de la API | Mira la terminal de `python run.py`: ahí sale el error. Y avísanos 🙏 |
| En la colección, `{{token_biblio}}` sale vacío | No corriste primero la carpeta 1 | Corre **Login bibliotecaria** antes que todo |
| La API no conecta con MySQL | MySQL apagado o `.env` mal | Prende el servicio de MySQL y revisa `DATABASE_URL` en `backend/.env` |

---

## 📖 14. Glosario express

| Palabra | En simple |
|---|---|
| **API** | El "garzón": el programa que recibe peticiones y responde con datos |
| **Endpoint** | Una "puerta" de la API: método + ruta. Ej. `POST /api/libros` |
| **Petición (request)** | Lo que mandas: método, URL, headers y body |
| **Respuesta (response)** | Lo que vuelve: código de estado y JSON |
| **JSON** | El formato de los datos: `{"nombre": "valor"}` |
| **Token / JWT** | La pulsera que te dan al hacer login; dura 1 hora |
| **Bearer** | La forma de mandar el token: `Authorization: Bearer <token>` |
| **Postman** | Programa pa' mandar peticiones a mano y ver las respuestas |
| **Colección** | Una carpeta de peticiones guardadas en Postman |
| **Variable `{{...}}`** | Un valor guardado que Postman reemplaza solo (URL, token, ids) |
| **CRUD** | Crear, Leer, Actualizar, Borrar = POST, GET, PUT, DELETE |
| **Swagger** (`/docs`) | La documentación interactiva de nuestra API, en el navegador |
| **localhost / 127.0.0.1** | "Mi propio computador" |
| **Puerto 5000** | La "puerta" del computador donde escucha nuestra API |

---

<p align="center">
  💪📮 <b>Con esto ingresan, listan y le muestran al profe que la API funciona de verdad.</b><br>
  <i>Primero se prende la API, después se abre Postman. Siempre en ese orden.</i> 😅
</p>
