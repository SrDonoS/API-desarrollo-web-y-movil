"""
E12 · POST /api/prestamos
E13 · GET  /api/prestamos
E14 · POST /api/prestamos/{id}/devolucion     (operación no-CRUD)

Todo esto es solo del bibliotecario: un socio recibe 403.
"""
from datetime import timedelta

from flask import current_app
from flask.views import MethodView
from flask_jwt_extended import current_user
from flask_smorest import Blueprint, abort
from sqlalchemy import and_, func, not_, select, update
from sqlalchemy.orm import selectinload

from ..extensiones import db
from ..esquemas import (ConsultaPrestamosSchema, PaginaPrestamosSchema,
                        PrestamoEntradaSchema, PrestamoSchema)
from ..modelos import Copia, Multa, Prestamo, Usuario
from ..seguridad import ROL_SOCIO, SEGURIDAD, bibliotecario_requerido
from ..tiempo import ahora, hoy

blp = Blueprint("Prestamos", __name__, url_prefix="/api/prestamos",
                description="Préstamos y devoluciones (solo bibliotecario)")


def opciones_prestamo():
    """Carga en pocas consultas todo lo que PrestamoSchema necesita (evita N+1)."""
    return (selectinload(Prestamo.copia).selectinload(Copia.libro),
            selectinload(Prestamo.socio),
            selectinload(Prestamo.multa))


@blp.route("")
class PrestamoLista(MethodView):

    @bibliotecario_requerido
    @blp.arguments(PrestamoEntradaSchema, error_status_code=400)
    @blp.response(201, PrestamoSchema)
    @blp.alt_response(400, description="Datos inválidos, o socio/copia inexistente")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(409, description="LIMITE_PRESTAMOS o COPIA_NO_DISPONIBLE")
    @blp.doc(summary="E12 · Registrar préstamo",
             description="Máximo 3 activos por socio. La copia debe estar disponible. "
                         "Vence a los 14 días.", **SEGURIDAD)
    def post(self, datos):
        # ⑤ Las referencias del CUERPO deben existir -> 400.
        #    with_for_update() bloquea la fila del socio hasta el commit: si dos
        #    bibliotecarios le prestan al mismo socio a la vez, el segundo espera
        #    y ve el préstamo del primero (así nunca pasa de 3). Ver READ COMMITTED
        #    en app/__init__.py.
        socio = db.session.scalar(
            select(Usuario).where(Usuario.id == datos["socio_id"]).with_for_update())
        if socio is None or socio.rol != ROL_SOCIO or not socio.activo:
            abort(400, message=f"El socio {datos['socio_id']} no existe o no está activo")

        copia = db.session.get(Copia, datos["copia_id"])
        if copia is None:
            abort(400, message=f"La copia {datos['copia_id']} no existe")

        # ⑥ Reglas del negocio -> 409. Primero el límite, después la copia (contrato).
        maximo = current_app.config["MAX_PRESTAMOS_ACTIVOS"]
        activos = db.session.scalar(
            select(func.count(Prestamo.id)).where(Prestamo.socio_id == socio.id,
                                                  Prestamo.estado == "activo"))
        if activos >= maximo:
            db.session.rollback()
            abort(409, message=f"El socio ya tiene {maximo} préstamos activos",
                  motivo="LIMITE_PRESTAMOS")

        # Cambio ATÓMICO: solo pasa a 'prestada' si sigue 'disponible'.
        # Si otro bibliotecario la prestó un milisegundo antes, rowcount = 0 -> 409.
        resultado = db.session.execute(
            update(Copia)
            .where(Copia.id == copia.id, Copia.estado == "disponible")
            .values(estado="prestada")
            .execution_options(synchronize_session="fetch"))
        if resultado.rowcount != 1:
            db.session.rollback()
            abort(409, message=f"La copia {copia.id} no está disponible",
                  motivo="COPIA_NO_DISPONIBLE")

        # ⑦ Crear: las fechas y el estado los pone el SERVIDOR (hora de Chile)
        momento = ahora()
        prestamo = Prestamo(
            socio_id=socio.id,
            copia_id=copia.id,
            bibliotecario_id=current_user.id,
            fecha_prestamo=momento,
            fecha_vencimiento=momento.date() + timedelta(days=current_app.config["DIAS_PRESTAMO"]),
            estado="activo",
        )
        db.session.add(prestamo)
        db.session.commit()                           # préstamo + copia: una sola transacción
        return prestamo

    @bibliotecario_requerido
    @blp.arguments(ConsultaPrestamosSchema, location="query", error_status_code=400)
    @blp.response(200, PaginaPrestamosSchema)
    @blp.alt_response(400, description="Filtro inválido")
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Un socio no puede ver préstamos ajenos (usa E15)")
    @blp.doc(summary="E13 · Listar préstamos de todos",
             description="Filtros: socio_id, estado, atrasado, multa (pendiente/pagada). "
                         "Del más reciente al más antiguo.", **SEGURIDAD)
    def get(self, q):
        stmt = select(Prestamo).options(*opciones_prestamo())
        if q.get("socio_id") is not None:
            stmt = stmt.where(Prestamo.socio_id == q["socio_id"])
        if q.get("estado"):
            stmt = stmt.where(Prestamo.estado == q["estado"])
        if q.get("atrasado") is not None:
            atrasado = and_(Prestamo.estado == "activo", Prestamo.fecha_vencimiento < hoy())
            stmt = stmt.where(atrasado if q["atrasado"] else not_(atrasado))
        if q.get("multa"):
            stmt = stmt.join(Multa, Multa.prestamo_id == Prestamo.id).where(
                Multa.estado == q["multa"])

        pagina = db.paginate(
            stmt.order_by(Prestamo.fecha_prestamo.desc(), Prestamo.id.desc()),
            page=q["pagina"], per_page=q["tam"], error_out=False)
        return {"total": pagina.total, "pagina": pagina.page, "tam": pagina.per_page,
                "paginas": pagina.pages, "items": pagina.items}


@blp.route("/<int:prestamo_id>/devolucion")
class Devolucion(MethodView):

    @bibliotecario_requerido
    @blp.response(200, PrestamoSchema)
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.alt_response(403, description="Requiere rol bibliotecario")
    @blp.alt_response(404, description="El préstamo no existe")
    @blp.alt_response(409, description="PRESTAMO_YA_DEVUELTO")
    @blp.doc(summary="E14 · Registrar devolución",
             description="Libera la copia. Si hubo atraso, crea la multa "
                         "(días de atraso × MULTA_POR_DIA). No recibe cuerpo.", **SEGURIDAD)
    def post(self, prestamo_id):
        # FOR UPDATE: si dos personas devuelven el mismo préstamo a la vez, la
        # segunda espera, ve 'devuelto' y recibe 409 (no se duplica la multa).
        prestamo = db.session.scalar(
            select(Prestamo).where(Prestamo.id == prestamo_id).with_for_update())
        if prestamo is None:
            abort(404, message="Préstamo no encontrado")
        if prestamo.estado == "devuelto":
            db.session.rollback()
            abort(409, message=f"El préstamo {prestamo_id} ya fue devuelto",
                  motivo="PRESTAMO_YA_DEVUELTO")

        momento = ahora()
        prestamo.fecha_devolucion = momento
        prestamo.estado = "devuelto"
        prestamo.copia.estado = "disponible"

        dias = (momento.date() - prestamo.fecha_vencimiento).days   # fechas, no horas
        if dias > 0:
            db.session.add(Multa(prestamo=prestamo, dias_atraso=dias, estado="pendiente",
                                 monto=dias * current_app.config["MULTA_POR_DIA"]))
        db.session.commit()
        return prestamo
