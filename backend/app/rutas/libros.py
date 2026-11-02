"""
E04 · GET    /api/libros
E05 · GET    /api/libros/{id}
E06 · POST   /api/libros
E07 · PUT    /api/libros/{id}
E08 · DELETE /api/libros/{id}
E09 · POST   /api/libros/{id}/copias      (recurso anidado)
"""
from flask.views import MethodView
from flask_jwt_extended import jwt_required
from flask_smorest import Blueprint, abort
from sqlalchemy import exists, or_, select
from sqlalchemy.exc import IntegrityError

from ..extensiones import db
from ..esquemas import (ConsultaLibrosSchema, CopiaEntradaSchema, CopiaSchema,
                        LibroDetalleSchema, LibroEntradaSchema, LibroSchema,
                        PaginaLibrosSchema)
from ..modelos import Categoria, Copia, Libro, Prestamo
from ..seguridad import SEGURIDAD, bibliotecario_requerido

blp = Blueprint("Libros", __name__, url_prefix="/api/libros",
                description="Catálogo (CRUD completo) y copias físicas")


# --- Ayudantes -----------------------------------------------------------------
def libro_o_404(libro_id):
    libro = db.session.get(Libro, libro_id)
    if libro is None:
        abort(404, message="Libro no encontrado")
    return libro


def validar_categoria(categoria_id):
    """Una referencia del CUERPO que no existe es 400 (el 404 es para la ruta)."""
    if db.session.get(Categoria, categoria_id) is None:
        abort(400, message=f"La categoría {categoria_id} no existe")


def isbn_ocupado(isbn, excepto_id=None):
    stmt = select(Libro.id).where(Libro.isbn == isbn)
    if excepto_id is not None:
        stmt = stmt.where(Libro.id != excepto_id)
    return db.session.scalar(stmt) is not None


def conflicto_isbn(mensaje="Ya existe un libro con ese ISBN"):
    abort(409, message=mensaje, motivo="ISBN_DUPLICADO")


# --- /api/libros -------------------------------------------------------------------
@blp.route("")
class LibroLista(MethodView):

    @jwt_required()
    @blp.arguments(ConsultaLibrosSchema, location="query", error_status_code=400)
    @blp.response(200, PaginaLibrosSchema)
    @blp.alt_response(400, description="Parámetro inválido (pagina < 1, tam fuera de 1-50…)")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.doc(summary="E04 · Listar el catálogo",
             description="Búsqueda en título y autor, filtro por categoría y disponibilidad, "
                         "paginación (máx. 50 por página).", **SEGURIDAD)
    def get(self, q):
        stmt = select(Libro)
        if q.get("buscar"):
            patron = f"%{q['buscar']}%"           # va como parámetro: sin inyección SQL
            stmt = stmt.where(or_(Libro.titulo.ilike(patron), Libro.autor.ilike(patron)))
        if q.get("categoria") is not None:
            stmt = stmt.where(Libro.categoria_id == q["categoria"])
        if q.get("disponible") is not None:
            con_copia_libre = select(Copia.libro_id).where(Copia.estado == "disponible")
            if q["disponible"]:
                stmt = stmt.where(Libro.id.in_(con_copia_libre))
            else:
                stmt = stmt.where(Libro.id.not_in(con_copia_libre))

        pagina = db.paginate(stmt.order_by(Libro.titulo, Libro.id),
                             page=q["pagina"], per_page=q["tam"], error_out=False)
        return {"total": pagina.total, "pagina": pagina.page, "tam": pagina.per_page,
                "paginas": pagina.pages, "items": pagina.items}

    @bibliotecario_requerido
    @blp.arguments(LibroEntradaSchema, error_status_code=400)
    @blp.response(201, LibroSchema)
    @blp.alt_response(400, description="Datos inválidos o categoría inexistente")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(409, description="ISBN_DUPLICADO")
    @blp.doc(summary="E06 · Crear libro", description="Nace sin copias (se agregan con E09).",
             **SEGURIDAD)
    def post(self, datos):
        validar_categoria(datos["categoria_id"])
        if isbn_ocupado(datos["isbn"]):
            conflicto_isbn()

        libro = Libro(**datos)
        db.session.add(libro)
        try:
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            conflicto_isbn()
        return libro, 201, {"Location": f"/api/libros/{libro.id}"}


# --- /api/libros/{id} ----------------------------------------------------------------
@blp.route("/<int:libro_id>")
class LibroDetalle(MethodView):

    @jwt_required()
    @blp.response(200, LibroDetalleSchema)
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(404, description="El libro no existe")
    @blp.doc(summary="E05 · Detalle de un libro",
             description="Incluye sus copias y el estado de cada una (no quién la tiene).",
             **SEGURIDAD)
    def get(self, libro_id):
        return libro_o_404(libro_id)

    @bibliotecario_requerido
    @blp.arguments(LibroEntradaSchema, error_status_code=400)
    @blp.response(200, LibroSchema)
    @blp.alt_response(400, description="Falta un campo (PUT exige todos) o categoría inexistente")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(404, description="El libro no existe")
    @blp.alt_response(409, description="ISBN_DUPLICADO: el ISBN es de OTRO libro")
    @blp.doc(summary="E07 · Reemplazar libro",
             description="PUT = reemplazo completo. Si no viene anio_publicacion, queda null.",
             **SEGURIDAD)
    def put(self, datos, libro_id):
        libro = libro_o_404(libro_id)
        validar_categoria(datos["categoria_id"])
        if isbn_ocupado(datos["isbn"], excepto_id=libro_id):
            conflicto_isbn("Ya existe otro libro con ese ISBN")

        for campo, valor in datos.items():          # se reemplazan TODOS los campos
            setattr(libro, campo, valor)
        try:
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            conflicto_isbn("Ya existe otro libro con ese ISBN")
        return libro

    @bibliotecario_requerido
    @blp.response(204)
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(404, description="El libro no existe")
    @blp.alt_response(409, description="LIBRO_CON_PRESTAMOS")
    @blp.doc(summary="E08 · Eliminar libro",
             description="Borra también sus copias. No se puede si alguna tiene préstamos.",
             **SEGURIDAD)
    def delete(self, libro_id):
        libro = libro_o_404(libro_id)

        tiene_prestamos = db.session.scalar(select(exists().where(
            Prestamo.copia_id == Copia.id, Copia.libro_id == libro_id)))
        if tiene_prestamos:
            abort(409, message="No se puede eliminar: el libro tiene préstamos registrados",
                  motivo="LIBRO_CON_PRESTAMOS")

        db.session.delete(libro)                    # cascade: sus copias se van con él
        try:
            db.session.commit()
        except IntegrityError:                      # justo le prestaron una copia
            db.session.rollback()
            abort(409, message="No se puede eliminar: el libro tiene préstamos registrados",
                  motivo="LIBRO_CON_PRESTAMOS")
        return ""


# --- /api/libros/{id}/copias -----------------------------------------------------------
@blp.route("/<int:libro_id>/copias")
class LibroCopias(MethodView):

    @bibliotecario_requerido
    @blp.arguments(CopiaEntradaSchema, error_status_code=400)
    @blp.response(201, CopiaSchema)
    @blp.alt_response(400, description="codigo_inventario faltante o con formato inválido")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(404, description="El libro de la ruta no existe")
    @blp.alt_response(409, description="CODIGO_DUPLICADO")
    @blp.doc(summary="E09 · Agregar copia física",
             description="El libro sale de la RUTA, nunca del cuerpo. La copia nace 'disponible'.",
             **SEGURIDAD)
    def post(self, datos, libro_id):
        libro_o_404(libro_id)
        codigo = datos["codigo_inventario"]
        if db.session.scalar(select(Copia.id).where(Copia.codigo_inventario == codigo)):
            abort(409, message="Ya existe una copia con ese código", motivo="CODIGO_DUPLICADO")

        copia = Copia(libro_id=libro_id, codigo_inventario=codigo, estado="disponible")
        db.session.add(copia)
        try:
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            abort(409, message="Ya existe una copia con ese código", motivo="CODIGO_DUPLICADO")
        return copia, 201, {"Location": f"/api/libros/{libro_id}"}
