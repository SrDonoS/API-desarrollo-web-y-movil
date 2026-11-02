"""
E15 · GET /api/mis-prestamos

LA regla estrella del caso: "un socio ve solo SUS préstamos".
No es un rol, es una regla de PERTENENCIA, y se resuelve en la ruta:
no hay id que cambiar, porque el socio sale del TOKEN firmado.
"""
from flask.views import MethodView
from flask_jwt_extended import current_user, jwt_required
from flask_smorest import Blueprint
from sqlalchemy import select

from ..extensiones import db
from ..esquemas import ConsultaMisPrestamosSchema, ListaPrestamosSchema
from ..modelos import Prestamo
from ..seguridad import SEGURIDAD
from .prestamos import opciones_prestamo

blp = Blueprint("MisPrestamos", __name__, url_prefix="/api/mis-prestamos",
                description="Los préstamos del dueño del token")


@blp.route("")
class MisPrestamos(MethodView):

    @jwt_required()
    @blp.arguments(ConsultaMisPrestamosSchema, location="query", error_status_code=400)
    @blp.response(200, ListaPrestamosSchema)
    @blp.alt_response(400, description="estado distinto de activo/devuelto")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.doc(summary="E15 · Mis préstamos (y mis multas)",
             description="Solo los préstamos del usuario del token. Un bibliotecario recibe "
                         "una lista vacía (no tiene préstamos).", **SEGURIDAD)
    def get(self, q):
        # 👇 La pertenencia: el socio sale del TOKEN, nunca de la ruta ni del query.
        #    (Si alguien manda ?socio_id=8, ese parámetro se ignora.)
        stmt = (select(Prestamo)
                .options(*opciones_prestamo())
                .where(Prestamo.socio_id == current_user.id))
        if q.get("estado"):
            stmt = stmt.where(Prestamo.estado == q["estado"])

        items = db.session.scalars(
            stmt.order_by(Prestamo.fecha_prestamo.desc(), Prestamo.id.desc())).all()
        return {"total": len(items), "items": items}
