"""
E16 · POST /api/multas/{id}/pago     (operación no-CRUD, solo bibliotecario)
"""
from flask.views import MethodView
from flask_smorest import Blueprint, abort
from sqlalchemy import select

from ..extensiones import db
from ..esquemas import MultaSchema
from ..modelos import Multa
from ..seguridad import SEGURIDAD, bibliotecario_requerido
from ..tiempo import ahora

blp = Blueprint("Multas", __name__, url_prefix="/api/multas",
                description="Pago de multas (solo bibliotecario)")


@blp.route("/<int:multa_id>/pago")
class PagoMulta(MethodView):

    @bibliotecario_requerido
    @blp.response(200, MultaSchema)
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(404, description="La multa no existe")
    @blp.alt_response(409, description="MULTA_YA_PAGADA")
    @blp.doc(summary="E16 · Registrar pago de multa",
             description="Pago total. Repetirlo da 409 (un doble clic no paga dos veces). "
                         "No recibe cuerpo.", **SEGURIDAD)
    def post(self, multa_id):
        multa = db.session.scalar(select(Multa).where(Multa.id == multa_id).with_for_update())
        if multa is None:
            abort(404, message="Multa no encontrada")
        if multa.estado == "pagada":
            db.session.rollback()
            abort(409, message=f"La multa {multa_id} ya está pagada", motivo="MULTA_YA_PAGADA")

        multa.estado = "pagada"
        multa.fecha_pago = ahora()
        db.session.commit()
        return multa
