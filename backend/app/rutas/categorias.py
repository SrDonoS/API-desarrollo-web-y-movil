"""
E10 · GET  /api/categorias
E11 · POST /api/categorias
"""
from flask.views import MethodView
from flask_jwt_extended import jwt_required
from flask_smorest import Blueprint, abort
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from ..extensiones import db
from ..esquemas import CategoriaEntradaSchema, CategoriaSchema
from ..modelos import Categoria, Libro
from ..seguridad import SEGURIDAD, bibliotecario_requerido

blp = Blueprint("Categorias", __name__, url_prefix="/api/categorias",
                description="Clasificación de los libros")

DUPLICADA = "Ya existe una categoría con ese nombre"


@blp.route("")
class CategoriaLista(MethodView):

    @jwt_required()
    @blp.response(200, CategoriaSchema(many=True))
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.doc(summary="E10 · Listar categorías", description="Con cuántos libros tiene cada una.",
             **SEGURIDAD)
    def get(self):
        stmt = (select(Categoria, func.count(Libro.id).label("total"))
                .outerjoin(Libro, Libro.categoria_id == Categoria.id)
                .group_by(Categoria.id, Categoria.nombre)
                .order_by(Categoria.nombre))
        resultado = []
        for categoria, total in db.session.execute(stmt):
            categoria.total_libros = total
            resultado.append(categoria)
        return resultado

    @bibliotecario_requerido
    @blp.arguments(CategoriaEntradaSchema, error_status_code=400)
    @blp.response(201, CategoriaSchema)
    @blp.alt_response(400, description="Nombre faltante o fuera de 3-60 caracteres")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(409, description="CATEGORIA_DUPLICADA")
    @blp.doc(summary="E11 · Crear categoría", **SEGURIDAD)
    def post(self, datos):
        nombre = datos["nombre"].strip()
        repetida = db.session.scalar(
            select(Categoria.id).where(func.lower(Categoria.nombre) == nombre.lower()))
        if repetida:
            abort(409, message=DUPLICADA, motivo="CATEGORIA_DUPLICADA")

        categoria = Categoria(nombre=nombre)
        db.session.add(categoria)
        try:
            db.session.commit()
        except IntegrityError:          # en MySQL el UNIQUE ya ignora mayúsculas y tildes
            db.session.rollback()
            abort(409, message=DUPLICADA, motivo="CATEGORIA_DUPLICADA")
        categoria.total_libros = 0
        return categoria
