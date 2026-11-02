# 📚 Guía de estudio — API REST de la Biblioteca Comunitaria

> 🎯 **Para qué sirve esta guía:** para que puedas **programar los 16 endpoints leyendo solo la planilla**, sin preguntarle nada a nadie. Aquí está explicado *qué* dice el contrato, *por qué* se decidió así y *cómo* se traduce a código (con el mismo estilo de la API del catálogo que vimos en clase: Flask + SQLAlchemy + Marshmallow + flask-smorest + JWT).
>
> 🧪 Todo lo que dice esta guía se probó: armé un prototipo de la API siguiendo el contrato al pie de la letra y pasó **95 pruebas automáticas** que recorren las 68 respuestas declaradas en la hoja 4-Salidas. O sea: el contrato *se puede* programar tal cual está escrito.

---

## 🗺️ Índice

1. [La idea en 30 segundos](#-1-la-idea-en-30-segundos)
2. [Conceptos que tienes que dominar](#-2-conceptos-que-tienes-que-dominar)
3. [Del caso al diseño](#-3-del-caso-al-diseño)
4. [Roles: cómo se traducen en la planilla](#-4-roles-cómo-se-traducen-en-la-planilla)
5. [La regla estrella: "un socio ve solo SUS préstamos"](#-5-la-regla-estrella-un-socio-ve-solo-sus-préstamos)
6. [Modelo de datos](#-6-modelo-de-datos)
7. [Las leyes globales de la API](#-7-las-leyes-globales-de-la-api)
8. [Fichas de los 16 endpoints](#-8-fichas-de-los-16-endpoints)
9. [Cómo se programa (Flask, como en clase)](#-9-cómo-se-programa-flask-como-en-clase)
10. [Plan de pruebas paso a paso](#-10-plan-de-pruebas-paso-a-paso)
11. [Los 8 errores frecuentes y cómo los esquivamos](#-11-los-8-errores-frecuentes-y-cómo-los-esquivamos)
12. [Preguntas que te pueden hacer (y qué responder)](#-12-preguntas-que-te-pueden-hacer-y-qué-responder)
13. [Antes de entregar](#-13-antes-de-entregar)
14. [Glosario express](#-14-glosario-express)

---

## ⚡ 1. La idea en 30 segundos

Una API REST es un **contrato** entre el backend y la app: *"si me pides esto, de esta forma, te respondo esto otro"*. La planilla **es** ese contrato. Si está bien escrita, el equipo del backend y el de la app pueden trabajar en paralelo sin hablarse.

| Qué | Cuánto | Dónde está en la planilla |
|---|---|---|
| 🧱 Entidades | **6**: Usuario, Categoria, Libro, Copia, Prestamo, Multa (29 campos) | 1-Entidades |
| 🔌 Endpoints | **16** (E01 a E16) | 2-Endpoints |
| 📥 Entradas detalladas | **54** | 3-Entradas |
| 📤 Respuestas detalladas | **68** (16 × 401, 9 × 403, 6 × 404, 10 × 409) | 4-Salidas |
| 🧾 Payloads JSON | **10** | 5-Payloads |
| 🛂 Filas de la matriz | **16** (una por endpoint) | 6-Matriz acceso |
| ✅ Contadores | **13 de 13 en OK** | 7-Checklist |

Los 16 endpoints de un vistazo:

| ID | Método | Ruta | Quién | Para qué |
|---|---|---|---|---|
| E01 | `POST` | `/api/auth/registro` | 🌍 cualquiera | Crear cuenta de socio |
| E02 | `POST` | `/api/auth/login` | 🌍 cualquiera | Obtener el token |
| E03 | `GET` | `/api/auth/yo` | 🔑 con token | ¿Quién soy? ¿Qué rol tengo? |
| E04 | `GET` | `/api/libros` | 🔑 con token | Catálogo (buscar, filtrar, paginar) |
| E05 | `GET` | `/api/libros/{id}` | 🔑 con token | Detalle de un libro + sus copias |
| E06 | `POST` | `/api/libros` | 👩‍💼 bibliotecario | Crear libro |
| E07 | `PUT` | `/api/libros/{id}` | 👩‍💼 bibliotecario | Reemplazar libro |
| E08 | `DELETE` | `/api/libros/{id}` | 👩‍💼 bibliotecario | Borrar libro |
| E09 | `POST` | `/api/libros/{id}/copias` | 👩‍💼 bibliotecario | Agregar copia física (anidado) |
| E10 | `GET` | `/api/categorias` | 🔑 con token | Listar categorías |
| E11 | `POST` | `/api/categorias` | 👩‍💼 bibliotecario | Crear categoría |
| E12 | `POST` | `/api/prestamos` | 👩‍💼 bibliotecario | Registrar préstamo |
| E13 | `GET` | `/api/prestamos` | 👩‍💼 bibliotecario | Ver préstamos de todos |
| E14 | `POST` | `/api/prestamos/{id}/devolucion` | 👩‍💼 bibliotecario | Registrar devolución (y multa) |
| E15 | `GET` | `/api/mis-prestamos` | 🙋 el socio dueño | Ver MIS préstamos (y mis multas) |
| E16 | `POST` | `/api/multas/{id}/pago` | 👩‍💼 bibliotecario | Registrar pago de multa |

> 💡 **CRUD completo** = sobre **Libro** (la entidad principal): listar (E04), ver uno (E05), crear (E06), modificar (E07), eliminar (E08). ✅

---

## 🧠 2. Conceptos que tienes que dominar

### 2.1 🏷️ La ruta es un SUSTANTIVO, el método es el VERBO

La ruta nombra **la cosa** (el recurso). El método HTTP dice **qué haces** con ella.

| ❌ Mal (verbo en la ruta) | ✅ Bien | Por qué |
|---|---|---|
| `POST /api/crearLibro` | `POST /api/libros` | "Crear" ya lo dice `POST` |
| `GET /api/obtenerLibros` | `GET /api/libros` | "Obtener" ya lo dice `GET` |
| `POST /api/devolverPrestamo?id=40` | `POST /api/prestamos/40/devolucion` | La devolución es un **sustantivo**: un sub-recurso del préstamo |
| `GET /api/prestamosDelSocio?id=7` | `GET /api/mis-prestamos` | La pertenencia se expresa en la ruta (ver §5) |

Los métodos que usamos:

| Método | Sobre la colección `/api/libros` | Sobre un elemento `/api/libros/12` | ¿Idempotente? |
|---|---|---|---|
| `GET` | Lista | Devuelve ese elemento | ✅ Sí |
| `POST` | Crea uno nuevo | (lo usamos para acciones: `/devolucion`, `/pago`) | ❌ No |
| `PUT` | — | Reemplaza **completo** | ✅ Sí |
| `DELETE` | — | Elimina | ✅ Sí |

> 🔁 **Idempotente** = repetir la petición deja el sistema igual. Si la app reintenta un `PUT` por un corte de red, no pasa nada; si reintenta un `POST /api/prestamos`, ¡crearía dos préstamos! Por eso en E14 y E16 un segundo intento responde **409** en vez de hacer el trabajo dos veces.

### 2.2 🚦 Los códigos de estado que usa nuestra API

| Código | Nombre | Emoji-resumen | En nuestra API significa… |
|---|---|---|---|
| **200** | OK | ✅ | Salió bien y te devuelvo datos |
| **201** | Created | 🆕 | Creé algo nuevo (E01, E06, E09, E11, E12) |
| **204** | No Content | 🗑️ | Salió bien y no hay nada que devolver (E08). **Sin cuerpo** |
| **400** | Bad Request | 📝❌ | Me mandaste datos mal formados, incompletos, prohibidos, o un id del **cuerpo** que no existe |
| **401** | Unauthorized | 🤷 | **No sé quién eres**: falta el token, es falso o expiró |
| **403** | Forbidden | 🚫 | **Sé quién eres, pero esto no te corresponde** (eres socio y esto es de bibliotecario) |
| **404** | Not Found | 🔍 | El id que pusiste **en la ruta** no existe |
| **409** | Conflict | 💥 | Tus datos están bien, pero **chocan con el estado del sistema** (cupo lleno, copia ya prestada, ISBN repetido…) |

> ⚠️ Nunca devolvemos **500** a propósito. Si aparece un 500, es que faltó una validación.
> ⚠️ Elegimos **400** para errores de validación (no 422) y lo usamos en **toda** la API. Consistencia > preferencia.

### 2.3 🤷 vs 🚫 — 401 y 403 NO son lo mismo

Piensa en el edificio de la biblioteca:

- 🤷 **401** → Llegas sin carnet (o con uno falso o vencido). El guardia: *"No sé quién eres"*. → La app te manda **al login**.
- 🚫 **403** → Muestras tu carnet de socio y quieres entrar a la bodega del personal. El guardia: *"Sé quién eres, pero no puedes pasar"*. → La app muestra **"no tienes permiso"**, y **NO** te manda al login (volver a loguearte no cambia tu rol).

### 2.4 📝 vs 💥 — 400 y 409

- **400**: el problema está **en lo que mandaste**. Ej.: `"isbn": "978-03"` (formato malo), falta `copia_id`, mandaste `"rol": "bibliotecario"`.
- **409**: lo que mandaste **es válido**, pero **choca con lo que ya hay**. Ej.: el ISBN ya lo tiene otro libro, la copia ya está prestada, el socio ya tiene 3 préstamos, la multa ya estaba pagada.

> 🧪 Prueba mental: *"¿Este mismo JSON habría funcionado ayer?"* Si la respuesta es "sí, cambió el estado del sistema" → **409**. Si "no, nunca funcionaría" → **400**.

### 2.5 🔍 ¿404 o 400 cuando un id no existe?

Regla de nuestra API (la misma del ejemplo de clase con `categoria_id`):

| Dónde viene el id | Si no existe → | Ejemplo |
|---|---|---|
| En la **RUTA** (`/api/libros/999`) | **404** | El recurso que pediste no existe |
| En el **CUERPO** (`{"copia_id": 999}`) | **400** | El recurso existe (préstamos), lo que está mal es un dato que enviaste |

### 2.6 🔑 JWT en un minuto

```
1. App → POST /api/auth/login  {"email": "...", "clave": "..."}
2. Servidor revisa el HASH de la clave y FIRMA un token con:
      sub = "7"            (el id del usuario, como texto)
      rol = "socio"        (claim adicional)
      exp = ahora + 1 hora
3. App guarda el token y en CADA petición manda:
      Authorization: Bearer eyJhbGciOi...
4. Servidor verifica firma y vencimiento → sabe quién eres SIN consultar sesiones.
```

- El **rol viaja dentro del token** → verificar "¿es bibliotecario?" no cuesta una consulta a la base.
- El **id del usuario viaja dentro del token** → por eso `/api/mis-prestamos` no necesita id en la ruta 😉.
- El token **no está cifrado** (es base64): jamás metas la clave ni datos sensibles dentro.
- Dura **1 hora**. En esta versión **no hay refresh**: cuando expira → 401 → volver a hacer login.

---

## 🔎 3. Del caso al diseño

El PDF dice: subrayar **sustantivos** (→ entidades) y **verbos** (→ endpoints). Así quedó:

| Frase del caso | Lo que encontramos | Decisión de diseño |
|---|---|---|
| "Una biblioteca presta **libros** a sus **socios**" | Entidades Libro y Usuario (rol socio) | Socio y bibliotecario son ambos `Usuario`, con un campo `rol` |
| "Cada libro tiene **autor**, **categoría**…" | Autor y Categoria | **Categoria = entidad** (se filtra y se lista). **Autor = campo de texto** (el caso no pide administrar autores) |
| "…y varias **copias físicas**" | Copia | ¡Clave! Se presta la **copia**, no el libro. Libro = la obra; Copia = el objeto con etiqueta |
| "hasta **3 préstamos activos**" | Regla de negocio | **409 LIMITE_PRESTAMOS** en E12 |
| "Los préstamos **duran 14 días**" | Regla | El servidor calcula `fecha_vencimiento = hoy + 14` |
| "generan **multa** por atraso" | Entidad Multa | Se crea al **devolver** con atraso: $500 × día (E14) |
| "El personal **registra** los préstamos y devoluciones" | Verbos → E12 y E14 | Solo rol **bibliotecario** |
| "los socios pueden **consultar** el catálogo" | Verbo → E04, E05, E10 | Requiere token (socio o bibliotecario) |
| "y **ver sus propios** préstamos, pero **no los de otros**" | Regla de **pertenencia** | `GET /api/mis-prestamos` (§5) |

> 🧩 **Decisiones que tomamos nosotros** (el caso no las dice, y por eso quedaron escritas en la planilla): tarifa de la multa **$500/día**, el catálogo **requiere token**, el registro de socios es **abierto**, el pago de la multa es **total**. Si el profe pregunta, la respuesta es: *"el caso no lo especifica, lo decidimos y lo dejamos explícito en el contrato"*.

---

## 🎭 4. Roles: cómo se traducen en la planilla

La planilla trae columnas genéricas (**Público, Autenticado, Dueño del recurso, Administrador**). Así se mapean nuestros 3 roles:

| Rol del caso | ¿Cómo lo reconoce el servidor? | Columna en la planilla |
|---|---|---|
| 🌍 **Anónimo** | No manda token | *Público* / *Anónimo* |
| 🙋 **Socio** | Token con `rol = "socio"` | *Autenticado* (y *Dueño del recurso* sobre SUS datos) |
| 👩‍💼 **Bibliotecario** | Token con `rol = "bibliotecario"` | *Administrador* |

- 🔑 **Autenticado** = cualquier usuario con token válido.
- 🙋 **Dueño del recurso** = el socio actuando sobre **sus propios** datos. Solo E15 usa este nivel.
- 👩‍💼 ¿De dónde salen los bibliotecarios? **No** se registran por la API (E01 siempre crea socios). Se cargan con un comando inicial, igual que el `flask --app run init-db` del curso, que crea usuarios de prueba.

Matriz resumida (la completa está en la hoja 6):

| Endpoints | 🌍 Anónimo | 🙋 Socio | 👩‍💼 Bibliotecario |
|---|---|---|---|
| E01, E02 (registro, login) | ✅ | ✅ | ✅ |
| E03, E04, E05, E10 (yo, catálogo, categorías) | ❌ 401 | ✅ | ✅ |
| E15 (mis-prestamos) | ❌ 401 | ✅ solo los suyos | ✅ (lista vacía: no tiene préstamos) |
| E06–E09, E11–E14, E16 (gestión) | ❌ 401 | ❌ 403 | ✅ |

---

## 🔐 5. La regla estrella: "un socio ve solo SUS préstamos"

La pista del caso dice: *"eso no es un rol, es una regla de **pertenencia**. Pensar cómo se expresa en la ruta"*.

¿Por qué no es un rol? Porque Ana y Pedro tienen **el mismo rol** (socio). Lo que los diferencia es **de quién es el dato**. Un decorador de rol no basta.

### Las 3 opciones que se podían elegir

| Opción | Ejemplo | Veredicto |
|---|---|---|
| ❌ Filtro en query, sin control | `GET /api/prestamos?socio_id=7` | **Falla de seguridad**: Ana cambia el 7 por un 8 y ve los de Pedro |
| ⚠️ Id en la ruta + verificación | `GET /api/socios/7/prestamos` y el servidor compara `7 == id del token` (si no → 403) | Funciona, pero **depende de que nadie olvide el `if`** en cada endpoint |
| ✅ **Nuestra elección** | `GET /api/mis-prestamos` | **No hay id que cambiar**: el socio sale del token. Seguro por diseño |

### Cómo queda blindado (defensa en capas) 🛡️

1. **`/api/mis-prestamos` no recibe id**: la consulta SIEMPRE es `WHERE socio_id = <id del token>`.
2. Si Ana intenta `GET /api/mis-prestamos?socio_id=8` → el parámetro **se ignora** (no está declarado) y sigue viendo **solo lo suyo**. (Lo probamos ✅).
3. La puerta "de todos" (`GET /api/prestamos`, E13) es **solo del bibliotecario** → si Ana la prueba: **403**.
4. No existe `GET /api/prestamos/{id}` → no hay forma de pedir el préstamo 40 "a ver si es mío".
5. En el catálogo (E05) se muestra si una copia está **prestada**, pero **no a quién** (eso sería dato de otro socio).

### El código que lo resuelve (¡son 2 líneas clave!) ✨

```python
@blp.route("")                       # url_prefix="/api/mis-prestamos"
class MisPrestamos(MethodView):

    @jwt_required()                                             # E15
    @blp.arguments(ConsultaMisPrestamosSchema, location="query", error_status_code=400)
    @blp.response(200, ListaPrestamosSchema)
    def get(self, q):
        # 👇 La regla de pertenencia: el socio sale del TOKEN, nunca de la ruta ni del cuerpo
        stmt = select(Prestamo).where(Prestamo.socio_id == current_user.id)
        if q.get("estado"):
            stmt = stmt.where(Prestamo.estado == q["estado"])
        items = db.session.scalars(
            stmt.order_by(Prestamo.fecha_prestamo.desc(), Prestamo.id.desc())).all()
        return {"total": len(items), "items": items}
```

> 🎤 **Si te preguntan** *"¿Un usuario puede acceder a datos de otro cambiando el id en la ruta?"* → **"No. El endpoint del socio no tiene id en la ruta: el servidor toma el id del token firmado, que el usuario no puede alterar sin invalidar la firma. Y el listado general es solo para bibliotecarios: un socio recibe 403."**

---

## 🧱 6. Modelo de datos

### 6.1 Diagrama de relaciones

```
 Categoria 1 ───< N  Libro  1 ───< N  Copia  1 ───< N  Prestamo  1 ─── 0..1  Multa
  (PROTECT)          (CASCADE)                (PROTECT)          (PROTECT)
                                                  │  │
                                       socio_id   │  │  bibliotecario_id
                                                  ▼  ▼
                                                Usuario   (PROTECT en ambas)
```

Léelo así: *una categoría tiene muchos libros; un libro tiene muchas copias; una copia tiene muchos préstamos a lo largo del tiempo (pero solo uno activo a la vez); un préstamo tiene como máximo una multa*.

> 💡 El `id` de cada tabla no aparece en la hoja 1 porque lo asigna la base de datos (así lo pide la planilla). El cliente **nunca** lo envía.

### 6.2 Las entidades, campo por campo

**👤 Usuario** (socios y bibliotecarios)

| Campo | Tipo | Oblig. | Único | Regla |
|---|---|---|---|---|
| nombre | str | Sí | No | 3–100 caracteres |
| rut | str | Sí | **Sí** | `^[0-9]{7,8}-[0-9Kk]$`, sin puntos; se guarda con K mayúscula |
| email | email | Sí | **Sí** | Formato válido; se guarda en minúsculas; es el "usuario" del login |
| clave | str | Sí | No | Mín. 8. Se guarda **solo el hash** (`clave_hash`). Nunca sale en respuestas |
| rol | enum | Sí | No | `socio` / `bibliotecario`. **Lo pone el servidor** |
| activo | bool | Sí | No | Default `true`. Si es `false`: login 401 y no se le presta (400) |
| creado | fecha y hora | Sí | No | Lo pone el servidor |

**🏷️ Categoria**: `nombre` (str, 3–60, **único sin distinguir mayúsculas**). En respuestas se agrega `total_libros` (calculado).

**📖 Libro** (la obra)

| Campo | Tipo | Oblig. | Único | Regla |
|---|---|---|---|---|
| titulo | str | Sí | No | 2–200 |
| autor | str | Sí | No | 3–120 (texto, no entidad) |
| isbn | str | Sí | **Sí** | `^([0-9]{9}[0-9X]\|[0-9]{13})$`, sin guiones |
| anio_publicacion | int | No | No | 1450 – año actual; si no viene → `null` |
| categoria_id | FK → Categoria | Sí | No | Debe existir (si no, 400) |
| *(calculados)* | | | | `copias_total`, `copias_disponibles`, `disponible` |

**📗 Copia** (el objeto físico con etiqueta)

| Campo | Tipo | Oblig. | Único | Regla |
|---|---|---|---|---|
| libro_id | FK → Libro | Sí | No | Viene de la **ruta** en E09 |
| codigo_inventario | str | Sí | **Sí** | `^[A-Z0-9-]{3,30}$` (ej. `LIB-000031`) |
| estado | enum | Sí | No | `disponible` / `prestada`. **Lo maneja el servidor** |
| fecha_ingreso | fecha | Sí | No | Hoy, lo pone el servidor |

**🔄 Prestamo**

| Campo | Tipo | Oblig. | Regla |
|---|---|---|---|
| socio_id | FK → Usuario | Sí | Usuario existente, rol socio, activo. Máx. 3 activos |
| copia_id | FK → Copia | Sí | Debe existir y estar `disponible` |
| bibliotecario_id | FK → Usuario | Sí | **El usuario del token** (quién prestó). No se expone |
| fecha_prestamo | fecha y hora | Sí | Ahora (servidor) |
| fecha_vencimiento | fecha | Sí | `fecha_prestamo + 14 días` (servidor) |
| fecha_devolucion | fecha y hora | No | `null` hasta que se devuelve (E14) |
| estado | enum | Sí | `activo` / `devuelto` |
| *(calculados)* | | | `atrasado` (bool), `dias_atraso` (int) |

**💸 Multa**

| Campo | Tipo | Oblig. | Regla |
|---|---|---|---|
| prestamo_id | FK → Prestamo | Sí | **Único** (relación 1:1) |
| dias_atraso | int | Sí | ≥ 1 |
| monto | int | Sí | `dias_atraso × 500` (pesos, sin decimales) |
| estado | enum | Sí | `pendiente` / `pagada` |
| fecha_pago | fecha y hora | No | `null` hasta E16 |

### 6.3 ¿Qué pasa al borrar? (decisión de borrado) 🗑️

| Relación | Decisión | Por qué |
|---|---|---|
| Libro → Categoria | **PROTECT** | No se puede borrar una categoría con libros |
| Copia → Libro | **CASCADE** | Al borrar un libro, sus copias se van con él… **pero E08 primero verifica que ninguna copia tenga préstamos** (si tiene → 409) |
| Prestamo → Copia | **PROTECT** | El historial de préstamos no se pierde |
| Prestamo → Usuario (socio y bibliotecario) | **PROTECT** | Los usuarios no se borran: se desactivan (`activo = false`) |
| Multa → Prestamo | **PROTECT** | Los préstamos nunca se borran |

### 6.4 🧮 Los campos calculados (no son columnas)

| Campo | Fórmula |
|---|---|
| `copias_total` | cantidad de copias del libro |
| `copias_disponibles` | copias con `estado == "disponible"` |
| `disponible` | `copias_disponibles > 0` |
| `total_libros` (categoría) | cantidad de libros de la categoría |
| `atrasado` | `estado == "activo"` **y** `hoy > fecha_vencimiento` |
| `dias_atraso` | `max(0, fin − fecha_vencimiento)` en días, donde `fin` = fecha de devolución (si ya se devolvió) u hoy (si sigue activo) |

> 📅 **Ejemplo de multa:** prestado el 20-09, vence el 04-10. Si se devuelve el 04-10 → 0 días, sin multa ✅. Si se devuelve el 07-10 → 3 días × $500 = **$1.500** 💸.

### 6.5 🙅 Lo que el cliente NUNCA envía

`id` · `rol` · `activo` · `creado` · `estado` (de copia, préstamo o multa) · `fecha_prestamo` · `fecha_vencimiento` · `fecha_devolucion` · `fecha_pago` · `bibliotecario_id` · `monto` · `libro_id` (en E09 viene de la ruta).

Si alguno llega en el **cuerpo** → **400** "Campo no permitido". Todo esto lo calcula o asigna el servidor.

---

## 📏 7. Las leyes globales de la API

Estas reglas valen para **todos** los endpoints. Si las aplicas, ya tienes resuelto el 70% del trabajo 💪.

### Ley 1 — Formato único de error 🧯

```json
{ "error": "Mensaje legible", "codigo": 400 }
```

- Errores de validación (400) agregan `detalles`, con la lista de problemas por campo:
  ```json
  { "error": "Datos inválidos en: isbn", "codigo": 400, "detalles": { "isbn": ["10 o 13 dígitos, sin guiones."] } }
  ```
- Los **409** agregan `motivo`, un código fijo para que la app sepa **cuál** conflicto ocurrió:
  ```json
  { "error": "El socio ya tiene 3 préstamos activos", "codigo": 409, "motivo": "LIMITE_PRESTAMOS" }
  ```

Todos los `motivo` posibles:

| motivo | Endpoint | Cuándo |
|---|---|---|
| `USUARIO_DUPLICADO` | E01 | RUT o email ya registrados |
| `ISBN_DUPLICADO` | E06, E07 | Otro libro ya tiene ese ISBN |
| `LIBRO_CON_PRESTAMOS` | E08 | Alguna copia del libro tiene préstamos |
| `CODIGO_DUPLICADO` | E09 | El `codigo_inventario` ya existe |
| `CATEGORIA_DUPLICADA` | E11 | Ya hay una categoría con ese nombre |
| `LIMITE_PRESTAMOS` | E12 | El socio ya tiene 3 préstamos activos |
| `COPIA_NO_DISPONIBLE` | E12 | La copia está prestada |
| `PRESTAMO_YA_DEVUELTO` | E14 | Se intentó devolver dos veces |
| `MULTA_YA_PAGADA` | E16 | Se intentó pagar dos veces |

### Ley 2 — El orden en que se revisan las cosas 🪜

Cuando una petición tiene varios problemas a la vez, responde **el primero** de esta escalera:

```
 ① 401  ¿Hay token válido?                       (decorador @jwt_required / @bibliotecario_requerido)
 ② 403  ¿El rol alcanza?                         (decorador @bibliotecario_requerido)
 ③ 400  ¿El cuerpo / query tienen buen formato?  (@blp.arguments + esquema Marshmallow)
 ④ 404  ¿Existe el id de la RUTA?                (primer if dentro de la función)
 ⑤ 400  ¿Existen los ids del CUERPO?             (categoria_id, socio_id, copia_id)
 ⑥ 409  ¿Choca con el estado del sistema?        (duplicados, límites, disponibilidad)
 ⑦ ✅   Hacer el trabajo y responder 200/201/204
```

> 💡 Esto sale **solo** si pones los decoradores en este orden: primero el de seguridad, luego `@blp.arguments`, luego `@blp.response`. Es exactamente como en la API del curso.

### Ley 3 — Campos que sobran

- En el **cuerpo** JSON: cualquier campo no declarado → **400** ("Campo no permitido en esta petición."). Así nadie puede colar `id`, `rol` o fechas.
- En el **query string**: los parámetros desconocidos **se ignoran** (comportamiento normal de flask-smorest).

### Ley 4 — Fechas 📅

| Tipo | Formato | Ejemplo |
|---|---|---|
| fecha | `AAAA-MM-DD` | `"2026-10-27"` |
| fecha y hora | `AAAA-MM-DDTHH:MM:SS` (hora local, sin microsegundos) | `"2026-10-13T10:30:00"` |

### Ley 5 — Paginación 📄

Los listados grandes (E04, E13) responden siempre igual:

```json
{ "total": 37, "pagina": 1, "tam": 10, "paginas": 4, "items": [ ... ] }
```

`pagina` ≥ 1 (default 1) · `tam` entre 1 y 50 (default 10). Fuera de rango → **400** (no se recorta en silencio).
Los listados chicos (E10, E15) no se paginan. E15 responde `{ "total", "items" }` y E10 responde una lista `[ ... ]`.

### Ley 6 — Cabeceras 📨

- Peticiones con cuerpo: `Content-Type: application/json`.
- Endpoints protegidos: `Authorization: Bearer <token>`.
- Respuestas 201 de E06 y E09: `Location: /api/libros/{id}`.

### Ley 7 — Constantes del negocio (en `config.py`, nunca "a mano" en el código) ⚙️

```python
MAX_PRESTAMOS_ACTIVOS = 3     # regla del caso
DIAS_PRESTAMO = 14            # regla del caso
MULTA_POR_DIA = 500           # decisión del equipo (el caso no da el monto)
```

---

## 🧾 8. Fichas de los 16 endpoints

Cada ficha junta lo que está repartido en las hojas 2, 3 y 4 de la planilla, más los **pasos** en el orden exacto en que hay que programarlos. 
Los datos de las tablas salen de la misma fuente que llenó el Excel, así que coinciden 1 a 1. 🔗

### E01 · `POST /api/auth/registro`

- **Qué hace:** Crea una cuenta de socio (registro abierto).
- **Quién puede:** 🌍 Cualquiera, sin token · **Token:** No · **Éxito:** `201`
- **Regla de negocio:** El rol NO se acepta desde el cliente: siempre se crea 'socio'. RUT y email no se repiten (409).

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `nombre` | cuerpo (JSON) | str | Sí | Entre 3 y 100 caracteres (se aplica strip) | 400 Bad Request | `"Ana Rojas Pérez"` |
| `rut` | cuerpo (JSON) | str | Sí | Regex ^[0-9]{7,8}-[0-9Kk]$ (sin puntos). Si ya existe → 409 (ver 4-Salidas) | 400 Bad Request | `"12345678-5"` |
| `email` | cuerpo (JSON) | email | Sí | Formato de correo válido; se guarda en minúsculas. Si ya existe → 409 | 400 Bad Request | `"ana.rojas@correo.cl"` |
| `clave` | cuerpo (JSON) | str | Sí | Mínimo 8 caracteres. Nunca se devuelve | 400 Bad Request | `"clave-segura-123"` |
| `id, rol, activo (prohibidos)` | cuerpo (JSON) | str | No | NO se aceptan: el servidor asigna id y rol='socio'. Todo campo no declarado se rechaza | 400 Bad Request | `"rol": "bibliotecario" → 400` |

**🛠️ Pasos para programarlo**

1. Validar el cuerpo con `RegistroSchema` (nombre, rut, email, clave). Cualquier otro campo, como `rol` o `id` → **400**.
2. Normalizar: `rut.upper()`, `email.strip().lower()`, `nombre.strip()`.
3. Si ya existe un usuario con ese RUT **o** ese email → **409** `USUARIO_DUPLICADO`.
4. Crear `Usuario(rol="socio")` ← el rol va **fijo en el código**. Guardar `set_clave(clave)` (hash).
5. Responder **201** con el usuario (sin la clave: `load_only=True` en el esquema).

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| 🆕 **201** | La cuenta se creó | `Usuario: {"id", "nombre", "rut", "email", "rol": "socio", "activo", "creado"}. Nunca la clave` | El rol siempre es 'socio' |
| 📝 **400** | Falta un campo, formato inválido (RUT, email, clave < 8) o vino un campo prohibido (id, rol) | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` | detalles indica qué campo falló |
| 💥 **409** | El RUT o el email ya están registrados | `{"error": "El RUT o el correo ya están registrados", "codigo": 409, "motivo": "USUARIO_DUPLICADO"}` | Datos válidos que chocan con lo ya guardado: 409, no 400 |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E01).*

> 💡 El rol **jamás** se acepta desde el cliente: si se aceptara, cualquiera se registraría como bibliotecario. Los bibliotecarios se crean con el comando inicial.

---

### E02 · `POST /api/auth/login`

- **Qué hace:** Entrega el token a partir de email y clave.
- **Quién puede:** 🌍 Cualquiera, sin token · **Token:** No · **Éxito:** `200`
- **Regla de negocio:** Mismo mensaje si el email no existe o la clave es incorrecta. El token dura 1 hora.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `email` | cuerpo (JSON) | email | Sí | Formato de correo válido | 400 Bad Request | `"ana.rojas@correo.cl"` |
| `clave` | cuerpo (JSON) | str | Sí | No vacía. Si no coincide con el hash → 401, con el mismo mensaje que un email inexistente | 400 Bad Request | `"clave-segura-123"` |

**🛠️ Pasos para programarlo**

1. Validar el cuerpo (`email`, `clave`) → **400** si falta algo.
2. Buscar el usuario por `email` en minúsculas.
3. Si no existe **o** `verificar_clave()` da False → **401** "Correo o contraseña incorrectos" (¡el MISMO mensaje!).
4. Si `activo == False` → **401** "La cuenta está desactivada".
5. `create_access_token(identity=str(u.id), additional_claims={"rol": u.rol})`.
6. Responder **200** con `access_token`, `token_type: "Bearer"`, `expira_en: 3600` y `usuario`.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | Credenciales correctas y cuenta activa | `{"access_token", "token_type": "Bearer", "expira_en": 3600, "usuario": {mismo formato que E03}}` | La app guarda el token y lo envía en cada petición |
| 📝 **400** | Falta email o clave, o el email no tiene formato válido | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 🤷 **401** | El email no existe o la clave es incorrecta (o la cuenta está desactivada) | `{"error": "Correo o contraseña incorrectos", "codigo": 401}` | MISMO mensaje si el email no existe o la clave falla: no revelar qué cuentas existen |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E02).*

> 💡 Mismo mensaje si el correo no existe o si la clave está mala: así un atacante no puede averiguar qué correos están registrados.

---

### E03 · `GET /api/auth/yo`

- **Qué hace:** Devuelve los datos del usuario dueño del token.
- **Quién puede:** 🔑 Cualquier usuario con token (socio o bibliotecario) · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** La app lo usa para saber quién inició sesión y su rol. El id del socio es su 'número de socio'.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente (formato 'Bearer <token>') | 401 Unauthorized | `Bearer eyJhbGciOi...` |

**🛠️ Pasos para programarlo**

1. `@jwt_required()` → **401** si no hay token válido.
2. Responder **200** con `current_user` (lo resuelve el `user_lookup_loader`, igual que en clase).

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | El token es válido | `Usuario: {"id", "nombre", "rut", "email", "rol", "activo", "creado"}` | El id es el 'número de socio' que se muestra en la app |
| 🤷 **401** | No se envió la cabecera Authorization | `{"error": "Falta el token. Envíe la cabecera Authorization: Bearer <token>", "codigo": 401}` | El cliente vuelve al login |
| 🤷 **401** | El token fue alterado, está mal formado o expiró (dura 1 hora) | `{"error": "El token no es válido o expiró", "codigo": 401}` | No hay refresh en esta versión: volver al login |

> 💡 La app lo llama al abrirse para decidir qué menú mostrar (socio o bibliotecario) y para mostrar el **número de socio** (= el `id`).

---

### E04 · `GET /api/libros`

- **Qué hace:** Lista el catálogo con búsqueda, filtros y paginación.
- **Quién puede:** 🔑 Cualquier usuario con token (socio o bibliotecario) · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** Tamaño de página máximo 50. Cada libro informa copias_total y copias_disponibles.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente (formato 'Bearer <token>') | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `buscar` | query string | str | No | Entre 1 y 100 caracteres. Busca en título y autor, sin distinguir mayúsculas | 400 Bad Request | `soledad` |
| `categoria` | query string | int | No | Entero ≥ 1. Si la categoría no existe, la lista sale vacía (no es error) | 400 Bad Request | `2` |
| `disponible` | query string | bool | No | true = solo libros con al menos 1 copia disponible; false = solo libros sin copias disponibles | 400 Bad Request | `true` |
| `pagina` | query string | int | No | Entero ≥ 1. Por defecto 1 | 400 Bad Request | `1` |
| `tam` | query string | int | No | Entre 1 y 50. Por defecto 10 | 400 Bad Request | `10` |

**🛠️ Pasos para programarlo**

1. `@jwt_required()` → **401**.
2. Validar el query con `ConsultaLibrosSchema` (`location="query"`) → **400** si un valor es inválido.
3. `buscar` → `titulo ILIKE %x% OR autor ILIKE %x%`. `categoria` → `categoria_id == x`.
4. `disponible=true` → libros cuyo id está en (copias con estado disponible); `false` → los que NO están.
5. Ordenar por `titulo`, paginar con `db.paginate(...)`.
6. Responder **200** `{total, pagina, tam, paginas, items}`.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | Consulta correcta (items puede venir vacío) | `{"total", "pagina", "tam", "paginas", "items": [libro]}. Libro = {"id", "titulo", "autor", "isbn", "anio_publicacion", "categoria": {id, nombre}, "copias_total", "copias_disponibles", "disponible"}` | Ordenado por título |
| 📝 **400** | Parámetro inválido: pagina < 1, tam fuera de 1-50, disponible no booleano, etc. | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |

> 💡 `tam=51` es **400**, no se recorta en silencio. Si `categoria` no existe, la lista sale vacía (filtrar no es un error).

---

### E05 · `GET /api/libros/{id}`

- **Qué hace:** Detalle de un libro, con sus copias físicas y el estado de cada una.
- **Quién puede:** 🔑 Cualquier usuario con token (socio o bibliotecario) · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** No revela qué socio tiene una copia prestada (sería dato de otro socio).

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente (formato 'Bearer <token>') | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `id` | ruta | int | Sí | El libro debe existir | 404 Not Found | `12` |

**🛠️ Pasos para programarlo**

1. `@jwt_required()` → **401**.
2. `db.session.get(Libro, id)`; si es `None` → **404**.
3. Responder **200** con `LibroDetalleSchema` (incluye `copias: [{id, codigo_inventario, estado}]`).

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | El libro existe | `Libro (mismo formato que E04) + "copias": [{"id", "codigo_inventario", "estado"}]` | No incluye quién tiene la copia prestada |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🔍 **404** | No existe un libro con ese id | `{"error": "Libro no encontrado", "codigo": 404}` |  |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E05).*

> 💡 El socio ve **si** hay copias disponibles, pero **no quién** tiene las prestadas (eso es dato de otro socio).

---

### E06 · `POST /api/libros`

- **Qué hace:** Agrega un libro al catálogo.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `201`
- **Regla de negocio:** ISBN único (409). La categoría debe existir (400). Nace sin copias.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `titulo` | cuerpo (JSON) | str | Sí | Entre 2 y 200 caracteres | 400 Bad Request | `"Cien años de soledad"` |
| `autor` | cuerpo (JSON) | str | Sí | Entre 3 y 120 caracteres | 400 Bad Request | `"Gabriel García Márquez"` |
| `isbn` | cuerpo (JSON) | str | Sí | Regex ^([0-9]{9}[0-9X]\|[0-9]{13})$ (sin guiones). Si otro libro ya lo tiene → 409 | 400 Bad Request | `"9780307474728"` |
| `anio_publicacion` | cuerpo (JSON) | int | No | Entre 1450 y el año actual. Si no viene: null | 400 Bad Request | `1967` |
| `categoria_id` | cuerpo (JSON) | int | Sí | La categoría debe existir (se verifica ANTES de insertar) | 400 Bad Request | `2` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** sin token / **403** si es socio.
2. Validar con `LibroEntradaSchema` → **400** (incluye `id` u otros campos no permitidos).
3. ¿Existe `categoria_id`? No → **400**.
4. ¿Algún libro ya tiene ese `isbn`? Sí → **409** `ISBN_DUPLICADO`.
5. Insertar y responder **201** + cabecera `Location: /api/libros/{id}`.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| 🆕 **201** | El libro se creó | `El libro creado (formato de E04) con el id que asignó el servidor; copias_total = 0` | Las copias se agregan después con E09 · Cabecera `Location: /api/libros/{id}` |
| 📝 **400** | Falta un campo, formato inválido (isbn, año), campo prohibido (id) o la categoría no existe | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` | La categoría se verifica ANTES de insertar |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 💥 **409** | Ya existe un libro con ese ISBN | `{"error": "Ya existe un libro con ese ISBN", "codigo": 409, "motivo": "ISBN_DUPLICADO"}` |  |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E06).*

> 💡 Verifica la categoría **antes** de insertar: si dejas que la base de datos reviente por la FK, terminas devolviendo un 500.

---

### E07 · `PUT /api/libros/{id}`

- **Qué hace:** Reemplaza todos los datos de un libro.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** PUT = reemplazo completo: se envían todos los campos. El ISBN no puede ser el de otro libro (409).

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `id` | ruta | int | Sí | El libro debe existir | 404 Not Found | `12` |
| `titulo` | cuerpo (JSON) | str | Sí | Igual que en E06 | 400 Bad Request | `"Cien años de soledad"` |
| `autor` | cuerpo (JSON) | str | Sí | Igual que en E06 | 400 Bad Request | `"Gabriel García Márquez"` |
| `isbn` | cuerpo (JSON) | str | Sí | Igual que en E06. Puede ser el mismo que ya tenía, pero no el de OTRO libro (409) | 400 Bad Request | `"9780307474728"` |
| `anio_publicacion` | cuerpo (JSON) | int | No | Igual que en E06. Si no viene queda null (PUT reemplaza todo) | 400 Bad Request | `1967` |
| `categoria_id` | cuerpo (JSON) | int | Sí | Igual que en E06 | 400 Bad Request | `2` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403**.
2. Validar con el **mismo** `LibroEntradaSchema` de E06 (PUT exige todos los obligatorios) → **400**.
3. ¿Existe el libro de la ruta? No → **404**.
4. ¿Existe `categoria_id`? No → **400**.
5. ¿El `isbn` lo tiene **otro** libro (`id != este`)? Sí → **409** `ISBN_DUPLICADO`.
6. Reemplazar **todos** los campos (si no vino `anio_publicacion`, queda `null`). Responder **200**.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | El libro se actualizó | `El libro actualizado (formato de E04)` |  |
| 📝 **400** | Falta algún campo obligatorio (PUT exige todos), formato inválido o la categoría no existe | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 🔍 **404** | No existe un libro con ese id | `{"error": "Libro no encontrado", "codigo": 404}` |  |
| 💥 **409** | El ISBN enviado pertenece a OTRO libro | `{"error": "Ya existe otro libro con ese ISBN", "codigo": 409, "motivo": "ISBN_DUPLICADO"}` | Mantener el mismo ISBN del libro NO es conflicto |

> 💡 PUT **reemplaza todo**: si no mandas `anio_publicacion`, queda `null`. Mantener el mismo ISBN del propio libro **no** es conflicto.

---

### E08 · `DELETE /api/libros/{id}`

- **Qué hace:** Elimina un libro junto con sus copias.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `204`
- **Regla de negocio:** No se puede si alguna de sus copias tiene préstamos, activos o históricos (409).

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `id` | ruta | int | Sí | El libro debe existir | 404 Not Found | `12` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403**.
2. ¿Existe el libro? No → **404**.
3. ¿Existe algún préstamo (activo o histórico) de alguna de sus copias? Sí → **409** `LIBRO_CON_PRESTAMOS`.
4. `db.session.delete(libro)` (las copias se borran en cascada). Responder **204** sin cuerpo.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| 🗑️ **204** | El libro y sus copias se eliminaron | `Sin cuerpo` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 🔍 **404** | No existe un libro con ese id | `{"error": "Libro no encontrado", "codigo": 404}` |  |
| 💥 **409** | Alguna copia del libro tiene préstamos (activos o históricos) | `{"error": "No se puede eliminar: el libro tiene préstamos registrados", "codigo": 409, "motivo": "LIBRO_CON_PRESTAMOS"}` | Protege el historial de préstamos y multas |

> 💡 Sin este 409, borrar un libro arrastraría su historial de préstamos y multas. Un libro sin préstamos sí se puede borrar (y sus copias con él).

---

### E09 · `POST /api/libros/{id}/copias`

- **Qué hace:** Registra una nueva copia física de un libro.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `201`
- **Regla de negocio:** Recurso anidado: la copia pertenece al libro de la ruta. codigo_inventario único (409). Nace 'disponible'.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `id` | ruta | int | Sí | Id del LIBRO al que pertenece la copia; debe existir | 404 Not Found | `12` |
| `codigo_inventario` | cuerpo (JSON) | str | Sí | Regex ^[A-Z0-9-]{3,30}$. Si ya existe → 409 | 400 Bad Request | `"LIB-000033"` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403**.
2. Validar `codigo_inventario` con la regex → **400**.
3. ¿Existe el libro de la ruta? No → **404**.
4. ¿Ya existe ese `codigo_inventario`? Sí → **409** `CODIGO_DUPLICADO`.
5. Crear `Copia(libro_id=<id de la ruta>, estado="disponible")` (`fecha_ingreso` = hoy). Responder **201** + `Location: /api/libros/{id}`.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| 🆕 **201** | La copia se registró | `{"id", "libro_id", "codigo_inventario", "estado": "disponible", "fecha_ingreso"}` | Location apunta al libro: la copia se ve en su detalle (E05) · Cabecera `Location: /api/libros/{id}` |
| 📝 **400** | Falta codigo_inventario o no cumple el formato | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 🔍 **404** | No existe el libro indicado en la ruta | `{"error": "Libro no encontrado", "codigo": 404}` |  |
| 💥 **409** | Ya existe una copia con ese codigo_inventario | `{"error": "Ya existe una copia con ese código", "codigo": 409, "motivo": "CODIGO_DUPLICADO"}` |  |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E09).*

> 💡 Recurso anidado: el `libro_id` sale de la **ruta**, nunca del cuerpo. La copia no tiene GET propio: se ve en el detalle del libro (E05).

---

### E10 · `GET /api/categorias`

- **Qué hace:** Lista las categorías con cuántos libros tiene cada una.
- **Quién puede:** 🔑 Cualquier usuario con token (socio o bibliotecario) · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** Ordenadas por nombre. Sirve para el filtro del catálogo.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente (formato 'Bearer <token>') | 401 Unauthorized | `Bearer eyJhbGciOi...` |

**🛠️ Pasos para programarlo**

1. `@jwt_required()` → **401**.
2. `SELECT categoria, COUNT(libro.id)` con LEFT JOIN y GROUP BY, ordenado por nombre (igual que el ejemplo de clase).
3. Responder **200** con la lista `[{id, nombre, total_libros}]`.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | Consulta correcta | `[{"id", "nombre", "total_libros"}]` | Ordenadas por nombre |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |

> 💡 Sirve para llenar el selector de categorías del filtro del catálogo en la app.

---

### E11 · `POST /api/categorias`

- **Qué hace:** Crea una categoría.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `201`
- **Regla de negocio:** Nombre único, sin distinguir mayúsculas (409).

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `nombre` | cuerpo (JSON) | str | Sí | Entre 3 y 60 caracteres. Si ya existe (sin distinguir mayúsculas) → 409 | 400 Bad Request | `"Novela"` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403**.
2. Validar `nombre` (3–60) → **400**.
3. ¿Existe una categoría con `lower(nombre) == lower(nuevo)`? Sí → **409** `CATEGORIA_DUPLICADA`.
4. Insertar y responder **201** con `total_libros: 0`.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| 🆕 **201** | La categoría se creó | `{"id", "nombre", "total_libros": 0}` |  |
| 📝 **400** | Falta el nombre o no tiene entre 3 y 60 caracteres | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 💥 **409** | Ya existe una categoría con ese nombre (sin distinguir mayúsculas) | `{"error": "Ya existe una categoría con ese nombre", "codigo": 409, "motivo": "CATEGORIA_DUPLICADA"}` |  |

> 💡 "Novela" y "NOVELA" son la misma categoría → 409.

---

### E12 · `POST /api/prestamos`

- **Qué hace:** Registra el préstamo de una copia a un socio.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `201`
- **Regla de negocio:** Máximo 3 préstamos activos por socio (409). La copia debe estar disponible (409). Vence a los 14 días.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `socio_id` | cuerpo (JSON) | int | Sí | Usuario existente, con rol socio y activo. Si ya tiene 3 préstamos activos → 409 | 400 Bad Request | `7` |
| `copia_id` | cuerpo (JSON) | int | Sí | La copia debe existir (400). Si no está 'disponible' → 409 | 400 Bad Request | `31` |
| `fechas, estado, id (prohibidos)` | cuerpo (JSON) | str | No | NO se aceptan: el servidor calcula fecha_prestamo, fecha_vencimiento (+14 días) y estado | 400 Bad Request | `"fecha_vencimiento": "..." → 400` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403**.
2. Validar el cuerpo: solo `socio_id` y `copia_id` → **400** (si mandan fechas, estado o id → 400).
3. Buscar el socio: si no existe, no tiene `rol == "socio"` o `activo == False` → **400**.
4. Buscar la copia: si no existe → **400**.
5. Contar préstamos `activo` del socio: si son ≥ 3 → **409** `LIMITE_PRESTAMOS` *(se revisa PRIMERO)*.
6. Si `copia.estado != "disponible"` → **409** `COPIA_NO_DISPONIBLE`.
7. Crear el préstamo: `fecha_prestamo = ahora`, `fecha_vencimiento = hoy + 14`, `estado = "activo"`, `bibliotecario_id = current_user.id`.
8. En la **misma transacción**: `copia.estado = "prestada"`. Un solo `commit()`. Responder **201**.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| 🆕 **201** | El préstamo se registró | `Préstamo: {"id", "socio": {id, nombre, rut}, "copia": {id, codigo_inventario}, "libro": {id, titulo}, "fecha_prestamo", "fecha_vencimiento", "fecha_devolucion", "estado", "atrasado", "dias_atraso", "multa"}. estado = 'activo', multa = null` | En la MISMA transacción la copia pasa a 'prestada' |
| 📝 **400** | Falta socio_id o copia_id, tipo incorrecto, o vino un campo prohibido (fechas, estado) | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 📝 **400** | El socio no existe, no tiene rol socio o está inactivo; o la copia no existe | `{"error": "El socio 7 no existe o no está activo", "codigo": 400}` | Id inexistente en el CUERPO = 400. El 404 se reserva para ids de la RUTA |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 💥 **409** | El socio ya tiene 3 préstamos activos | `{"error": "El socio ya tiene 3 préstamos activos", "codigo": 409, "motivo": "LIMITE_PRESTAMOS"}` | Se verifica ANTES que la disponibilidad de la copia |
| 💥 **409** | La copia no está disponible (ya está prestada) | `{"error": "La copia 31 no está disponible", "codigo": 409, "motivo": "COPIA_NO_DISPONIBLE"}` | 'motivo' le dice al cliente cuál de los dos 409 ocurrió |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E12).*

> 💡 Hay **dos 409** distintos: el campo `motivo` le dice a la app cuál mensaje mostrar. Y como el socio sale del cuerpo, el bibliotecario consigue el número de socio en la app del socio (E03).

---

### E13 · `GET /api/prestamos`

- **Qué hace:** Lista los préstamos de todos los socios, con filtros y paginación.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** Solo el bibliotecario ve préstamos de terceros: un socio recibe 403 y debe usar E15.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `socio_id` | query string | int | No | Entero ≥ 1. Solo préstamos de ese socio | 400 Bad Request | `7` |
| `estado` | query string | str | No | Solo 'activo' o 'devuelto' | 400 Bad Request | `activo` |
| `atrasado` | query string | bool | No | true = solo activos con fecha_vencimiento anterior a hoy; false = todos los demás | 400 Bad Request | `true` |
| `multa` | query string | str | No | Solo 'pendiente' o 'pagada': préstamos cuya multa está en ese estado | 400 Bad Request | `pendiente` |
| `pagina` | query string | int | No | Entero ≥ 1. Por defecto 1 | 400 Bad Request | `1` |
| `tam` | query string | int | No | Entre 1 y 50. Por defecto 10 | 400 Bad Request | `10` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403** (un socio no puede ver préstamos ajenos).
2. Validar el query → **400** (`estado` ∈ {activo, devuelto}, `multa` ∈ {pendiente, pagada}).
3. Filtros: `socio_id`; `estado`; `atrasado=true` → `estado = activo AND fecha_vencimiento < hoy` (`false` → lo contrario); `multa` → JOIN con Multa y filtrar por su estado.
4. Ordenar del más reciente al más antiguo y paginar. Responder **200**.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | Consulta correcta | `{"total", "pagina", "tam", "paginas", "items": [préstamo]} (préstamo con el formato de E12)` | Del más reciente al más antiguo |
| 📝 **400** | Filtro inválido: estado o multa con un valor no permitido, pagina < 1, tam > 50 | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El usuario es socio: no puede ver préstamos de otros | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | El socio ve los suyos en E15 |

> 💡 Para cobrar multas el bibliotecario usa `?multa=pendiente` (o `?socio_id=7&multa=pendiente`): cada préstamo trae el `id` de su multa, que es el que usa E16.

---

### E14 · `POST /api/prestamos/{id}/devolucion`

- **Qué hace:** Registra la devolución de un préstamo.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** No-CRUD. Sub-recurso único (singular). Libera la copia; si hay atraso crea la multa ($500/día). Ya devuelto → 409.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `id` | ruta | int | Sí | El préstamo debe existir. No recibe cuerpo (si llega, se ignora) | 404 Not Found | `40` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403**.
2. ¿Existe el préstamo? No → **404**.
3. Si `estado == "devuelto"` → **409** `PRESTAMO_YA_DEVUELTO`.
4. `fecha_devolucion = ahora`, `estado = "devuelto"`, `copia.estado = "disponible"`.
5. `dias = (hoy - fecha_vencimiento).days`. Si `dias > 0` → crear `Multa(dias_atraso=dias, monto=dias*500, estado="pendiente")`.
6. Un solo `commit()`. Responder **200** con el préstamo (y su `multa` o `null`).

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | La devolución se registró | `Préstamo (formato de E12) con estado "devuelto", fecha_devolucion y "multa": null si no hubo atraso, o {"id", "monto", "dias_atraso", "estado": "pendiente"}` | En la MISMA transacción la copia vuelve a 'disponible' |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 🔍 **404** | No existe un préstamo con ese id | `{"error": "Préstamo no encontrado", "codigo": 404}` |  |
| 💥 **409** | El préstamo ya estaba devuelto | `{"error": "El préstamo 40 ya fue devuelto", "codigo": 409, "motivo": "PRESTAMO_YA_DEVUELTO"}` | Evita liberar dos veces la copia o duplicar la multa |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E14).*

> 💡 La multa se calcula con **fechas** (`.date()`), no con horas. Devolver el mismo día del vencimiento = 0 días de atraso = sin multa.

---

### E15 · `GET /api/mis-prestamos`

- **Qué hace:** Lista los préstamos (con su multa) del usuario dueño del token.
- **Quién puede:** 🙋 El usuario dueño del token (sus propios datos) · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** Pertenencia expresada en la ruta: NO recibe id, el socio sale del token. No hay forma de pedir préstamos ajenos.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. De AQUÍ sale el id del socio: la ruta no recibe id | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `estado` | query string | str | No | Solo 'activo' o 'devuelto'. Sin filtro: todos | 400 Bad Request | `activo` |

**🛠️ Pasos para programarlo**

1. `@jwt_required()` → **401**. (No hay decorador de rol: la pertenencia la da la consulta).
2. Validar `estado` (opcional) → **400**.
3. Consulta: `WHERE socio_id = current_user.id` ← **el id sale del token**.
4. Ordenar del más reciente al más antiguo. Responder **200** `{total, items}`.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | Consulta correcta | `{"total", "items": [préstamo]} SOLO del usuario del token (préstamo con el formato de E12)` | Imposible ver préstamos ajenos: no hay id que cambiar. Un bibliotecario recibe lista vacía |
| 📝 **400** | estado con un valor distinto de 'activo' o 'devuelto' | `{"error": "Datos inválidos en: <campos>", "codigo": 400, "detalles": {"<campo>": ["<problema>"]}}` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E15).*

> 💡 No hay id en la ruta → no hay id que cambiar → **es imposible ver préstamos ajenos**. Si alguien manda `?socio_id=8`, se ignora.

---

### E16 · `POST /api/multas/{id}/pago`

- **Qué hace:** Registra el pago de una multa.
- **Quién puede:** 👩‍💼 Solo bibliotecario · **Token:** Sí · **Éxito:** `200`
- **Regla de negocio:** No-CRUD. Sub-recurso único (singular). Multa ya pagada → 409.

**📥 Entradas**

| Dato | Dónde | Tipo | Oblig. | Validación | Si no cumple | Ejemplo |
|---|---|---|---|---|---|---|
| `Authorization` | cabecera | str | Sí | Token válido y vigente. Además el rol debe ser bibliotecario: si es socio → 403 | 401 Unauthorized | `Bearer eyJhbGciOi...` |
| `id` | ruta | int | Sí | La multa debe existir. No recibe cuerpo (si llega, se ignora) | 404 Not Found | `9` |

**🛠️ Pasos para programarlo**

1. `@bibliotecario_requerido` → **401** / **403**.
2. ¿Existe la multa? No → **404**.
3. Si `estado == "pagada"` → **409** `MULTA_YA_PAGADA`.
4. `estado = "pagada"`, `fecha_pago = ahora`, `commit()`. Responder **200**.

**📤 Respuestas**

| Código | Cuándo | Cuerpo | Nota |
|---|---|---|---|
| ✅ **200** | El pago se registró | `{"id", "prestamo_id", "monto", "dias_atraso", "estado": "pagada", "fecha_pago"}` |  |
| 🤷 **401** | No se envió el token, es inválido o expiró | `{"error": "...", "codigo": 401}` | El cliente vuelve al login |
| 🚫 **403** | El token es válido, pero el usuario es socio (no bibliotecario) | `{"error": "Esta operación requiere rol de bibliotecario", "codigo": 403}` | NO volver al login: mostrar 'sin permiso' |
| 🔍 **404** | No existe una multa con ese id | `{"error": "Multa no encontrada", "codigo": 404}` |  |
| 💥 **409** | La multa ya estaba pagada | `{"error": "La multa 9 ya está pagada", "codigo": 409, "motivo": "MULTA_YA_PAGADA"}` |  |

🧾 *JSON de ejemplo completo en la hoja 5-Payloads (fila E16).*

> 💡 Un doble clic en "Registrar pago" no paga dos veces: el segundo intento recibe 409.

---

## 🧑‍💻 9. Cómo se programa (Flask, como en clase)

La buena noticia: **la estructura es la misma de la API del catálogo** (`api_catalogo_auth`). Cambian los modelos, los esquemas y las rutas; el esqueleto se reutiliza. Todos los fragmentos de esta sección vienen del prototipo que pasó las 95 pruebas ✅.

### 9.1 📁 Estructura de carpetas

```
api_biblioteca/
├── run.py                    (igual que en clase)
├── requirements.txt          (igual que en clase)
└── app/
    ├── __init__.py           crear_app(): registra 6 blueprints + callbacks JWT
    ├── config.py             + MAX_PRESTAMOS_ACTIVOS, DIAS_PRESTAMO, MULTA_POR_DIA
    ├── extensiones.py        (igual)
    ├── errores.py            + agrega "motivo" a los 409
    ├── seguridad.py          admin_requerido  →  bibliotecario_requerido
    ├── comandos.py           init-db: crea tablas + bibliotecario de prueba
    ├── modelos.py            Usuario, Categoria, Libro, Copia, Prestamo, Multa
    ├── esquemas.py           entrada (validan) y salida (serializan)
    └── rutas/
        ├── auth.py           E01 E02 E03
        ├── libros.py         E04 E05 E06 E07 E08 E09
        ├── categorias.py     E10 E11
        ├── prestamos.py      E12 E13 E14
        ├── mis_prestamos.py  E15
        └── multas.py         E16
```

### 9.2 🔄 Qué cambia respecto de la API del curso

| En la API del catálogo | En la biblioteca |
|---|---|
| Roles `admin` / `operador` | Roles `bibliotecario` / `socio` |
| Login con `usuario` (o email) | Login con `email` |
| `@admin_requerido` revisa `"admin"` | `@bibliotecario_requerido` revisa `"bibliotecario"` |
| Registro crea `operador` | Registro crea `socio` (y pide `nombre` y `rut`) |
| Existe `/api/auth/refresh` | **No está en el contrato** → no lo programes (o agrégalo primero a la planilla) |
| `PUT` parcial con `ProductoActualizarSchema` | `PUT` **completo**: reutiliza `LibroEntradaSchema` |
| Los 409 traen `error` y `codigo` | Los 409 traen además `motivo` |
| Todo es "leer = autenticado, escribir = admin" | Aparece la **pertenencia**: `/api/mis-prestamos` |

### 9.3 🛡️ `seguridad.py` — el decorador de rol

```python
from functools import wraps
from flask_jwt_extended import verify_jwt_in_request, get_jwt
from flask_smorest import abort


def bibliotecario_requerido(fn):
    """401 si no hay token válido; 403 si el token es de un socio."""
    @wraps(fn)
    def envoltorio(*args, **kwargs):
        verify_jwt_in_request()                        # 1) AUTENTICACIÓN -> 401
        if get_jwt().get("rol") != "bibliotecario":    # 2) AUTORIZACIÓN  -> 403
            abort(403, message="Esta operación requiere rol de bibliotecario")
        return fn(*args, **kwargs)
    return envoltorio
```

### 9.4 🧯 `errores.py` — el único cambio: agregar `motivo`

`abort(409, message="...", motivo="LIMITE_PRESTAMOS")` guarda `motivo` en `e.data`. En el manejador de errores del curso solo hay que copiarlo a la respuesta:

```python
        cuerpo = {"error": datos.get("message") or e.description, "codigo": e.code}
        if datos.get("motivo"):                 # <- lo único nuevo respecto de la API del curso
            cuerpo["motivo"] = datos["motivo"]
        return jsonify(cuerpo), e.code
```

### 9.5 🔑 Login: el rol viaja dentro del token

```python
token = create_access_token(identity=str(usuario.id),
                            additional_claims={"rol": usuario.rol})
return {"access_token": token, "token_type": "Bearer",
        "expira_en": 3600, "usuario": usuario}
```

Y en `config.py`: `JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)`.

### 9.6 🧱 Modelos clave: `Prestamo` y `Multa`

```python
class Prestamo(db.Model):
    __tablename__ = "prestamo"

    id = db.Column(db.Integer, primary_key=True)
    socio_id = db.Column(db.Integer, db.ForeignKey("usuario.id", ondelete="RESTRICT"),
                         nullable=False, index=True)
    copia_id = db.Column(db.Integer, db.ForeignKey("copia.id", ondelete="RESTRICT"),
                         nullable=False, index=True)
    bibliotecario_id = db.Column(db.Integer, db.ForeignKey("usuario.id", ondelete="RESTRICT"),
                                 nullable=False)
    fecha_prestamo = db.Column(db.DateTime, nullable=False)
    fecha_vencimiento = db.Column(db.Date, nullable=False)
    fecha_devolucion = db.Column(db.DateTime, nullable=True)
    estado = db.Column(db.String(10), nullable=False, default="activo")

    # Dos FK a la misma tabla (usuario): hay que decir cuál usa cada relación
    socio = db.relationship("Usuario", foreign_keys=[socio_id])
    copia = db.relationship("Copia")
    multa = db.relationship("Multa", back_populates="prestamo", uselist=False)

    @property
    def libro(self):
        return self.copia.libro

    @property
    def atrasado(self):
        return self.estado == "activo" and date.today() > self.fecha_vencimiento

    @property
    def dias_atraso(self):
        fin = self.fecha_devolucion.date() if self.fecha_devolucion else date.today()
        return max(0, (fin - self.fecha_vencimiento).days)


class Multa(db.Model):
    __tablename__ = "multa"

    id = db.Column(db.Integer, primary_key=True)
    prestamo_id = db.Column(db.Integer, db.ForeignKey("prestamo.id", ondelete="RESTRICT"),
                            nullable=False, unique=True)                      # 1:1
    dias_atraso = db.Column(db.Integer, nullable=False)
    monto = db.Column(db.Integer, nullable=False)
    estado = db.Column(db.String(10), nullable=False, default="pendiente")
    fecha_pago = db.Column(db.DateTime, nullable=True)

    prestamo = db.relationship("Prestamo", back_populates="multa")
```

Y en `Libro`, para el CASCADE hacia las copias:

```python
    copias = db.relationship("Copia", back_populates="libro", lazy="selectin",
                             cascade="all, delete-orphan")
```

> 💡 Los `@property` (`atrasado`, `dias_atraso`, `copias_disponibles`…) son los **campos calculados**: Marshmallow los lee igual que una columna, pero no ocupan espacio en la tabla. "Una regla del dominio vive en el modelo, no en la vista" (como `disponible` en la API del curso).

### 9.7 🔄 E12 — Registrar un préstamo (el endpoint con más reglas)

```python
@bibliotecario_requerido                                    # ① 401 / ② 403
@blp.arguments(PrestamoEntradaSchema, error_status_code=400)  # ③ 400 formato
@blp.response(201, PrestamoSchema)
def post(self, datos):
    # ⑤ Las referencias del CUERPO deben existir -> 400
    socio = db.session.get(Usuario, datos["socio_id"])
    if socio is None or socio.rol != "socio" or not socio.activo:
        abort(400, message=f"El socio {datos['socio_id']} no existe o no está activo")
    copia = db.session.get(Copia, datos["copia_id"])
    if copia is None:
        abort(400, message=f"La copia {datos['copia_id']} no existe")

    # ⑥ Reglas de negocio (estado del sistema) -> 409
    maximo = current_app.config["MAX_PRESTAMOS_ACTIVOS"]
    activos = db.session.scalar(select(func.count(Prestamo.id)).where(
        Prestamo.socio_id == socio.id, Prestamo.estado == "activo"))
    if activos >= maximo:
        abort(409, message=f"El socio ya tiene {maximo} préstamos activos",
              motivo="LIMITE_PRESTAMOS")
    if copia.estado != "disponible":
        abort(409, message=f"La copia {copia.id} no está disponible",
              motivo="COPIA_NO_DISPONIBLE")

    # ⑦ Crear: las fechas y el estado los pone el SERVIDOR
    ahora = datetime.now().replace(microsecond=0)
    prestamo = Prestamo(
        socio_id=socio.id, copia_id=copia.id, bibliotecario_id=current_user.id,
        fecha_prestamo=ahora,
        fecha_vencimiento=ahora.date() + timedelta(days=current_app.config["DIAS_PRESTAMO"]),
        estado="activo")
    copia.estado = "prestada"                # misma transacción
    db.session.add(prestamo)
    db.session.commit()
    return prestamo
```

### 9.8 📬 E14 — Registrar la devolución (y la multa)

```python
@bibliotecario_requerido
@blp.response(200, PrestamoSchema)
def post(self, pid):
    prestamo = db.session.get(Prestamo, pid)
    if prestamo is None:
        abort(404, message="Préstamo no encontrado")
    if prestamo.estado == "devuelto":
        abort(409, message=f"El préstamo {pid} ya fue devuelto",
              motivo="PRESTAMO_YA_DEVUELTO")

    ahora = datetime.now().replace(microsecond=0)
    prestamo.fecha_devolucion = ahora
    prestamo.estado = "devuelto"
    prestamo.copia.estado = "disponible"

    dias = (ahora.date() - prestamo.fecha_vencimiento).days
    if dias > 0:
        db.session.add(Multa(prestamo=prestamo, dias_atraso=dias, estado="pendiente",
                             monto=dias * current_app.config["MULTA_POR_DIA"]))
    db.session.commit()
    return prestamo
```

### 9.9 📝 Esquemas: tres trucos que te ahorran trabajo

```python
class BaseSchema(Schema):
    """Rechaza campos no declarados (id, rol, fechas...) -> 400."""
    error_messages = {"unknown": "Campo no permitido en esta petición."}

FECHA_HORA = "%Y-%m-%dT%H:%M:%S"     # 2026-10-13T10:30:00 (sin microsegundos)
fecha_prestamo = fields.DateTime(format=FECHA_HORA)

isbn = fields.Str(required=True, validate=validate.Regexp(
    r"^([0-9]{9}[0-9X]|[0-9]{13})$", error="10 o 13 dígitos, sin guiones."))
```

1. **Heredar de `BaseSchema`** en todos los esquemas de entrada → nadie cuela `id`, `rol` ni fechas.
2. **`format=FECHA_HORA`** en los `DateTime` de salida → las fechas salen como dice el contrato.
3. **`validate.Regexp`** y **`validate.OneOf([...])`** para RUT, ISBN, código de inventario y los enums de los filtros.

### 9.10 🌱 `comandos.py` — de dónde sale el primer bibliotecario

```python
USUARIOS = [  # nombre, rut, email, clave, rol
    ("Carlos Muñoz", "11111111-1", "biblio@biblioteca.cl", "biblio1234", "bibliotecario"),
    ("Ana Rojas Pérez", "12345678-5", "ana.rojas@correo.cl", "clave-segura-123", "socio"),
]
# flask --app run init-db  → crea tablas, estos usuarios y categorías de ejemplo
```

### 9.11 ⚠️ El orden de los decoradores importa

```python
@bibliotecario_requerido          # ① y ② : se ejecuta PRIMERO → 401 / 403
@blp.arguments(Esquema, error_status_code=400)   # ③ : después valida → 400
@blp.response(201, EsquemaSalida)
def post(self, datos): ...        # ④ ⑤ ⑥ ⑦ : los if dentro de la función
```

Si lo inviertes, un socio sin permiso que manda datos malos recibiría 400 en vez de 403, y estarías validando datos de alguien que ni siquiera puede usar el endpoint.

> 🐞 **Ojo con `error_status_code=400`**: sin eso, flask-smorest responde **422** y rompes la ley "400 en toda la API".

---

## 🧪 10. Plan de pruebas paso a paso

Ejecútalo en Swagger (`/docs`) o con `curl`, **en este orden**. Si todo da lo esperado, tu API cumple el contrato. 🏆

| # | Quién | Petición | Esperado |
|---|---|---|---|
| 1 | 🌍 | `POST /api/auth/registro` con los datos de Ana | **201**, `rol: "socio"`, sin clave |
| 2 | 🌍 | Repetir el mismo registro | **409** `USUARIO_DUPLICADO` |
| 3 | 🌍 | Registro con `"rol": "bibliotecario"` | **400** campo no permitido |
| 4 | 🌍 | Login de Ana con clave mala / con email inexistente | **401** y **el mismo mensaje** en ambos |
| 5 | 🌍 | Login de Ana correcto | **200** + token 🔑 |
| 6 | 🌍 | `GET /api/libros` sin token | **401** |
| 7 | 🙋 Ana | `POST /api/libros` | **403** (no **401**) |
| 8 | 👩‍💼 | `POST /api/categorias` "Novela", luego "NOVELA" | **201**, luego **409** |
| 9 | 👩‍💼 | `POST /api/libros` (Cien años…) y repetirlo | **201** + `Location`, luego **409** `ISBN_DUPLICADO` |
| 10 | 👩‍💼 | `POST /api/libros/12/copias` × 5 | **201** cada una |
| 11 | 🙋 Ana | `GET /api/libros?buscar=soledad&disponible=true` | **200**, `copias_disponibles: 5` |
| 12 | 👩‍💼 | `POST /api/prestamos` {Ana, copia 31} | **201**, vence en 14 días |
| 13 | 👩‍💼 | Otro préstamo de la copia 31 a otro socio | **409** `COPIA_NO_DISPONIBLE` |
| 14 | 👩‍💼 | 3 préstamos al socio 8 y luego un 4.º | **201** × 3, luego **409** `LIMITE_PRESTAMOS` |
| 15 | 👩‍💼 | `DELETE /api/libros/12` | **409** `LIBRO_CON_PRESTAMOS` |
| 16 | 🙋 Ana | `GET /api/mis-prestamos` | **200**, **solo** préstamos de Ana |
| 17 | 🙋 Ana | `GET /api/mis-prestamos?socio_id=8` | **200**, **sigue** viendo solo lo suyo 🛡️ |
| 18 | 🙋 Ana | `GET /api/prestamos` | **403** |
| 19 | 👩‍💼 | *(Simular atraso: en la BD, poner `fecha_vencimiento` 3 días atrás)* `POST /api/prestamos/{id}/devolucion` | **200**, multa de **$1.500** pendiente |
| 20 | 👩‍💼 | Devolver el mismo préstamo otra vez | **409** `PRESTAMO_YA_DEVUELTO` |
| 21 | 👩‍💼 | `GET /api/prestamos?multa=pendiente` | **200**, aparece el préstamo con su multa |
| 22 | 👩‍💼 | `POST /api/multas/{id}/pago` dos veces | **200**, luego **409** `MULTA_YA_PAGADA` |

Tres `curl` para arrancar (en Windows PowerShell usa `curl.exe` y comillas dobles escapadas, como en el `probar_api.ps1` del curso):

```bash
# Login del bibliotecario
curl -s -X POST http://127.0.0.1:5000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"biblio@biblioteca.cl","clave":"biblio1234"}'

# Registrar préstamo (pega el token)
curl -i -X POST http://127.0.0.1:5000/api/prestamos \
     -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" \
     -d '{"socio_id": 2, "copia_id": 1}'

# Mis préstamos (con el token de Ana)
curl -i http://127.0.0.1:5000/api/mis-prestamos -H "Authorization: Bearer <TOKEN_ANA>"
```

---

## 🚨 11. Los 8 errores frecuentes y cómo los esquivamos

| # | Error del PDF | Cómo lo resolvimos |
|---|---|---|
| 1 | Verbos en la ruta | Ninguna ruta tiene verbo. Las acciones son **sustantivos**: `/devolucion`, `/pago` |
| 2 | Olvidar el 401 | Los **14** endpoints protegidos declaran su 401 (16 filas en total) |
| 3 | Confundir 401 con 403 | 401 = sin token / token malo. 403 = socio intentando algo de bibliotecario |
| 4 | Olvidar el 404 | Los 6 endpoints con `{id}` en la ruta (E05, E07, E08, E09, E14, E16) tienen su 404 |
| 5 | No declarar ningún 409 | Hay **10** filas 409, cada una con su regla y su `motivo` |
| 6 | Aceptar el id en el cuerpo | `BaseSchema` rechaza `id`, `rol`, fechas y estados → 400. Hay filas explícitas en 3-Entradas (E01 y E12) |
| 7 | Matriz incompleta | 16 filas en la matriz = 16 endpoints en el catálogo |
| 8 | No pensar en datos ajenos | `/api/mis-prestamos` sin id + `/api/prestamos` solo bibliotecario + el catálogo no dice quién tiene cada copia |

---

## 🎤 12. Preguntas que te pueden hacer (y qué responder)

<details>
<summary>❓ ¿Por qué <code>/api/mis-prestamos</code> y no <code>/api/socios/{id}/prestamos</code>?</summary>

Porque con `{id}` en la ruta la seguridad depende de que el programador **no olvide** comparar ese id con el del token en cada endpoint. Con `/mis-prestamos` **no hay id que manipular**: el socio sale del token firmado. Es seguro *por diseño*, no *por disciplina*. (Ambas son válidas en REST; la nuestra deja menos espacio para errores).
</details>

<details>
<summary>❓ ¿"mis-prestamos" no es raro? ¿No debería ser solo sustantivos en plural?</summary>

Es un sustantivo en plural ("mis préstamos"), sin verbo. Es el mismo patrón que `/api/auth/yo` del curso o `/user/repos` de GitHub: un recurso relativo al usuario autenticado.
</details>

<details>
<summary>❓ ¿Por qué <code>/devolucion</code> y <code>/pago</code> van en singular?</summary>

Porque **no son colecciones**: un préstamo tiene **una sola** devolución y una multa tiene **un solo** pago. Son sub-recursos únicos. Las colecciones (`libros`, `copias`, `prestamos`, `multas`, `categorias`) sí van en plural.
</details>

<details>
<summary>❓ ¿Por qué la devolución es <code>POST</code> y no <code>PATCH /api/prestamos/{id}</code> con <code>{"estado":"devuelto"}</code>?</summary>

Porque devolver no es "editar un campo": dispara **efectos** (libera la copia, calcula y crea la multa). Modelarla como un sub-recurso que se crea (`POST .../devolucion`) deja la regla en un solo lugar y evita que alguien haga `PATCH {"estado":"activo"}` para "des-devolver" un préstamo.
</details>

<details>
<summary>❓ ¿Por qué un id inexistente en el cuerpo es 400 y no 404?</summary>

El 404 dice "el recurso **de la URL** no existe". En `POST /api/prestamos` la URL sí existe; lo que está mal es un **dato** que enviaste (`copia_id: 999`). Es la misma convención del ejemplo de clase con `categoria_id`.
</details>

<details>
<summary>❓ ¿Por qué el autor no es una entidad?</summary>

El caso no pide administrar autores (crear, listar, editar). Como texto se cumple todo lo que pide el caso, incluida la búsqueda (`?buscar=`). Si mañana se necesita (biografía, filtrar por autor exacto), se promueve a entidad.
</details>

<details>
<summary>❓ ¿Por qué el catálogo exige token si es "público"?</summary>

El caso dice "los **socios** pueden consultar el catálogo". Lo leímos literal: hay que ser socio (o bibliotecario). El anónimo puede registrarse e iniciar sesión. Si el profe prefiere un catálogo abierto, solo cambian E04, E05 y E10 a "Público" (y sus filas 401).
</details>

<details>
<summary>❓ ¿De dónde salió la multa de $500 por día?</summary>

El caso dice que hay multa, pero **no el monto**. Lo fijamos nosotros, lo escribimos en el contrato (para que nadie tenga que preguntar) y lo dejamos en `config.py` (`MULTA_POR_DIA`) para cambiarlo sin tocar el código.
</details>

<details>
<summary>❓ ¿Qué pasa si dos bibliotecarios prestan la misma copia al mismo tiempo?</summary>

Ambos podrían ver la copia "disponible" antes de que el otro guarde. El contrato ya define la respuesta correcta para el segundo: **409 `COPIA_NO_DISPONIBLE`**. Para garantizarlo en el código, se puede hacer el cambio de estado con un `UPDATE copia SET estado='prestada' WHERE id=? AND estado='disponible'` y revisar que haya afectado 1 fila (si afectó 0 → 409). Para esta etapa basta con la verificación normal.
</details>

<details>
<summary>❓ ¿Por qué un bibliotecario recibe una lista vacía en <code>/mis-prestamos</code> y no un 403?</summary>

Porque la regla es simple y uniforme: "mis préstamos = los préstamos donde yo soy el socio". Un bibliotecario no tiene préstamos, así que su lista está vacía. No hace falta una regla especial (ni un decorador más). Para ver los de un socio, usa E13.
</details>

<details>
<summary>❓ ¿Por qué el préstamo devuelto con multa dice <code>atrasado: false</code> pero <code>dias_atraso: 3</code>?</summary>

`atrasado` responde "¿está atrasado **ahora**?" y solo puede ser `true` mientras el préstamo sigue activo. `dias_atraso` responde "¿cuántos días se atrasó?", y para un préstamo devuelto queda fijo en los días que se atrasó al devolverlo.
</details>

<details>
<summary>❓ ¿Y el token de refresco?</summary>

No está en este contrato: el token dura 1 hora y luego se vuelve a hacer login. Si lo quieren agregar (como en la API del curso), primero se agrega a la planilla: `POST /api/auth/refresh`. **Primero el contrato, después el código.**
</details>

---

## ✅ 13. Antes de entregar

- [ ] Completar en la hoja **Instrucciones**: nombres de los dos integrantes y sección (dejé un texto "(completar…)" en esas celdas). El caso y la fecha ya están.
- [ ] Renombrar el archivo como pide el PDF: **`Apellido1_Apellido2_EspecAPI.xlsx`**.
- [ ] Abrir la hoja **7-Checklist** y confirmar **13 de 13** contadores en OK.
- [ ] Hacer **de verdad** la prueba final: pasarle la planilla a otra pareja y preguntar *"¿podrías programar esto sin preguntarme nada?"*. Si preguntan algo, eso que expliques es lo que falta escribir (y esta guía te sirve para responder).
- [ ] Leer las secciones **5** (pertenencia) y **2.3** (401 vs 403): son las que más se preguntan.

---

## 📖 14. Glosario express

| Término | En una línea |
|---|---|
| **Endpoint** | Método + ruta. Ej.: `POST /api/prestamos` |
| **Recurso** | La "cosa" que nombra la ruta (libros, préstamos…) |
| **Recurso anidado** | Un recurso que vive dentro de otro: `/api/libros/12/copias` |
| **Payload** | El JSON que viaja en el cuerpo de la petición o de la respuesta |
| **Query string** | Lo que va después del `?`: `?buscar=soledad&pagina=2` |
| **JWT** | Token firmado que dice quién eres y tu rol; va en `Authorization: Bearer …` |
| **Claim** | Un dato dentro del JWT (`sub` = id, `rol` = socio/bibliotecario) |
| **Autenticación** | Saber **quién** eres → si falla, 401 |
| **Autorización** | Saber **qué puedes** hacer → si falla, 403 |
| **Pertenencia** | Regla de "este dato es tuyo"; no es un rol |
| **Idempotente** | Repetirlo no cambia el resultado (GET, PUT, DELETE) |
| **PROTECT / CASCADE / SET NULL** | Qué pasa con los hijos al borrar al padre: impedir / arrastrar / desvincular |
| **Hash** | Huella irreversible de la clave; se guarda eso, nunca la clave |
| **Esquema (Marshmallow)** | Clase que valida la entrada, da forma a la salida y documenta en Swagger |
| **Contrato** | La planilla: lo que el backend promete y la app puede esperar |

---

<p align="center">💪📚 <b>Con la planilla + esta guía puedes programar los 16 endpoints sin preguntarle nada a nadie.</b> ¡Éxito! 🍀</p>
