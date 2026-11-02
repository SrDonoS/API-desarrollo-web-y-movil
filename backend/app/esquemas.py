"""
Esquemas de Marshmallow. Cada esquema hace tres cosas a la vez:

  1. VALIDA la entrada (hoja 3-Entradas): si algo no cumple -> 400.
  2. SERIALIZA la salida (hoja 4-Salidas): decide qué campos se exponen.
  3. DOCUMENTA: flask-smorest los usa para armar Swagger.

Regla clave: los esquemas de ENTRADA heredan de BaseSchema, que rechaza
cualquier campo no declarado. Así nadie puede colar id, rol, fechas ni estados.
"""
from datetime import date

from marshmallow import Schema, fields, validate

OBLIGATORIO = {
    "required": "Este campo es obligatorio.",
    "null": "Este campo no puede ser nulo.",
    "invalid": "El valor no tiene el tipo correcto.",
}
FECHA_HORA = "%Y-%m-%dT%H:%M:%S"     # 2026-10-13T10:30:00 (contrato: sin microsegundos)


def texto(min_, max_, **kw):
    return fields.Str(
        validate=validate.Length(min=min_, max=max_,
                                 error=f"Debe tener entre {min_} y {max_} caracteres."),
        error_messages=OBLIGATORIO, **kw)


def regex(patron, mensaje, **kw):
    return fields.Str(validate=validate.Regexp(patron, error=mensaje),
                      error_messages=OBLIGATORIO, **kw)


def entero(**kw):
    return fields.Int(error_messages=OBLIGATORIO, strict=True, **kw)   # "31" o 3.5 -> 400


def opciones(valores):
    return fields.Str(validate=validate.OneOf(
        valores, error="Valor no permitido. Use: " + ", ".join(valores) + "."))


class BaseSchema(Schema):
    """Base de las ENTRADAS: un campo no declarado -> 400."""
    error_messages = {"unknown": "Campo no permitido en esta petición."}


# ---------------------------------------------------------------------------
# Errores (para que Swagger muestre nuestro formato)
# ---------------------------------------------------------------------------
class ErrorSchema(Schema):
    error = fields.Str(metadata={"description": "Mensaje legible"})
    codigo = fields.Int(metadata={"description": "Mismo código HTTP"})
    detalles = fields.Dict(metadata={"description": "Solo en 400: campo -> lista de problemas"})
    motivo = fields.Str(metadata={"description": "Solo en 409: código fijo del conflicto"})


# ---------------------------------------------------------------------------
# Usuarios y autenticación (E01, E02, E03)
# ---------------------------------------------------------------------------
class UsuarioSchema(Schema):
    id = fields.Int(metadata={"description": "También es el 'número de socio'"})
    nombre = fields.Str()
    rut = fields.Str()
    email = fields.Str()
    rol = fields.Str(metadata={"description": "socio o bibliotecario"})
    activo = fields.Bool()
    creado = fields.DateTime(format=FECHA_HORA)


class RegistroSchema(BaseSchema):
    nombre = texto(3, 100, required=True, metadata={"example": "Ana Rojas Pérez"})
    rut = regex(r"^[0-9]{7,8}-[0-9Kk]$",
                "Formato 12345678-9: sin puntos, con guion y dígito verificador.",
                required=True, metadata={"example": "12345678-5"})
    email = fields.Email(required=True, metadata={"example": "ana.rojas@correo.cl"},
                         error_messages={**OBLIGATORIO,
                                         "invalid": "El correo no tiene un formato válido."})
    clave = fields.Str(required=True, load_only=True, error_messages=OBLIGATORIO,
                       validate=validate.Length(min=8, error="Debe tener al menos 8 caracteres."),
                       metadata={"example": "clave-segura-123"})


class LoginSchema(BaseSchema):
    email = fields.Email(required=True, metadata={"example": "biblio@biblioteca.cl"},
                         error_messages={**OBLIGATORIO,
                                         "invalid": "El correo no tiene un formato válido."})
    clave = fields.Str(required=True, load_only=True, error_messages=OBLIGATORIO,
                       validate=validate.Length(min=1, error="No puede estar vacía."),
                       metadata={"example": "biblio1234"})


class TokenSchema(Schema):
    access_token = fields.Str()
    token_type = fields.Str()
    expira_en = fields.Int(metadata={"description": "Segundos de vigencia (3600)"})
    usuario = fields.Nested(UsuarioSchema)


# ---------------------------------------------------------------------------
# Categorías (E10, E11)
# ---------------------------------------------------------------------------
class CategoriaSchema(Schema):
    id = fields.Int()
    nombre = fields.Str()
    total_libros = fields.Int()


class CategoriaEntradaSchema(BaseSchema):
    nombre = texto(3, 60, required=True, metadata={"example": "Novela"})


class CategoriaResumenSchema(Schema):
    id = fields.Int()
    nombre = fields.Str()


# ---------------------------------------------------------------------------
# Libros y copias (E04–E09)
# ---------------------------------------------------------------------------
class CopiaResumenSchema(Schema):
    id = fields.Int()
    codigo_inventario = fields.Str()
    estado = fields.Str(metadata={"description": "disponible o prestada"})


class CopiaSchema(Schema):
    id = fields.Int()
    libro_id = fields.Int()
    codigo_inventario = fields.Str()
    estado = fields.Str()
    fecha_ingreso = fields.Date()


class CopiaEntradaSchema(BaseSchema):
    codigo_inventario = regex(r"^[A-Z0-9-]{3,30}$",
                              "Entre 3 y 30 caracteres: solo MAYÚSCULAS, números y guion.",
                              required=True, metadata={"example": "LIB-000033"})


class LibroSchema(Schema):
    id = fields.Int()
    titulo = fields.Str()
    autor = fields.Str()
    isbn = fields.Str()
    anio_publicacion = fields.Int(allow_none=True)
    categoria = fields.Nested(CategoriaResumenSchema)
    copias_total = fields.Int()
    copias_disponibles = fields.Int()
    disponible = fields.Bool()


class LibroDetalleSchema(LibroSchema):
    copias = fields.List(fields.Nested(CopiaResumenSchema))


class LibroEntradaSchema(BaseSchema):
    """Sirve para POST (E06) y PUT (E07): PUT reemplaza TODO, así que exige lo mismo."""
    titulo = texto(2, 200, required=True, metadata={"example": "Cien años de soledad"})
    autor = texto(3, 120, required=True, metadata={"example": "Gabriel García Márquez"})
    isbn = regex(r"^([0-9]{9}[0-9X]|[0-9]{13})$",
                 "10 o 13 dígitos, sin guiones (el ISBN-10 puede terminar en X).",
                 required=True, metadata={"example": "9780307474728"})
    anio_publicacion = entero(
        load_default=None, allow_none=True, metadata={"example": 1967},
        validate=validate.Range(min=1450, max=date.today().year,
                                error="Debe estar entre 1450 y el año actual."))
    categoria_id = entero(required=True, metadata={"example": 1})


class ConsultaLibrosSchema(BaseSchema):
    buscar = fields.Str(validate=validate.Length(min=1, max=100,
                        error="Entre 1 y 100 caracteres."),
                        metadata={"description": "Busca en título y autor"})
    categoria = fields.Int(validate=validate.Range(min=1, error="Debe ser un entero ≥ 1."))
    disponible = fields.Bool(metadata={"description": "true: con copias libres · false: sin"})
    pagina = fields.Int(load_default=1, validate=validate.Range(min=1, error="La página parte en 1."))
    tam = fields.Int(load_default=10, validate=validate.Range(min=1, max=50, error="Entre 1 y 50."))


class PaginaLibrosSchema(Schema):
    total = fields.Int()
    pagina = fields.Int()
    tam = fields.Int()
    paginas = fields.Int()
    items = fields.List(fields.Nested(LibroSchema))


# ---------------------------------------------------------------------------
# Préstamos y multas (E12–E16)
# ---------------------------------------------------------------------------
class SocioResumenSchema(Schema):
    id = fields.Int()
    nombre = fields.Str()
    rut = fields.Str()


class CopiaMiniSchema(Schema):
    id = fields.Int()
    codigo_inventario = fields.Str()


class LibroMiniSchema(Schema):
    id = fields.Int()
    titulo = fields.Str()


class MultaResumenSchema(Schema):
    id = fields.Int()
    monto = fields.Int()
    dias_atraso = fields.Int()
    estado = fields.Str(metadata={"description": "pendiente o pagada"})


class MultaSchema(Schema):
    id = fields.Int()
    prestamo_id = fields.Int()
    monto = fields.Int()
    dias_atraso = fields.Int()
    estado = fields.Str()
    fecha_pago = fields.DateTime(format=FECHA_HORA, allow_none=True)


class PrestamoSchema(Schema):
    id = fields.Int()
    socio = fields.Nested(SocioResumenSchema)
    copia = fields.Nested(CopiaMiniSchema)
    libro = fields.Nested(LibroMiniSchema)
    fecha_prestamo = fields.DateTime(format=FECHA_HORA)
    fecha_vencimiento = fields.Date()
    fecha_devolucion = fields.DateTime(format=FECHA_HORA, allow_none=True)
    estado = fields.Str(metadata={"description": "activo o devuelto"})
    atrasado = fields.Bool()
    dias_atraso = fields.Int()
    multa = fields.Nested(MultaResumenSchema, allow_none=True)


class PrestamoEntradaSchema(BaseSchema):
    socio_id = entero(required=True, metadata={"example": 2})
    copia_id = entero(required=True, metadata={"example": 1})


class ConsultaPrestamosSchema(BaseSchema):
    socio_id = fields.Int(validate=validate.Range(min=1, error="Debe ser un entero ≥ 1."))
    estado = opciones(["activo", "devuelto"])
    atrasado = fields.Bool()
    multa = opciones(["pendiente", "pagada"])
    pagina = fields.Int(load_default=1, validate=validate.Range(min=1, error="La página parte en 1."))
    tam = fields.Int(load_default=10, validate=validate.Range(min=1, max=50, error="Entre 1 y 50."))


class ConsultaMisPrestamosSchema(BaseSchema):
    estado = opciones(["activo", "devuelto"])


class PaginaPrestamosSchema(Schema):
    total = fields.Int()
    pagina = fields.Int()
    tam = fields.Int()
    paginas = fields.Int()
    items = fields.List(fields.Nested(PrestamoSchema))


class ListaPrestamosSchema(Schema):
    total = fields.Int()
    items = fields.List(fields.Nested(PrestamoSchema))
