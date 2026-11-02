"""
Formato ÚNICO de error para toda la API (contrato, "Ley 1"):

    {"error": "...", "codigo": 404}
    {"error": "...", "codigo": 400, "detalles": {"campo": ["problema"]}}
    {"error": "...", "codigo": 409, "motivo": "LIMITE_PRESTAMOS"}

Así la app Flutter tiene UN solo manejador de errores.
"""
from flask import jsonify
from sqlalchemy.exc import SQLAlchemyError
from werkzeug.exceptions import HTTPException

from .extensiones import db


def registrar_errores(app):

    @app.errorhandler(HTTPException)
    def _http(e):
        datos = getattr(e, "data", None) or {}

        # Errores de validación de Marshmallow (vienen agrupados por "json" o "query")
        validacion = datos.get("messages")
        if validacion:
            detalles = validacion.get("json") or validacion.get("query") or validacion
            if isinstance(detalles, dict):
                mensaje = "Datos inválidos en: " + ", ".join(str(k) for k in detalles.keys())
            else:
                mensaje = "Datos inválidos"
            return jsonify({"error": mensaje, "codigo": e.code, "detalles": detalles}), e.code

        cuerpo = {"error": datos.get("message") or e.description, "codigo": e.code}
        if datos.get("motivo"):          # abort(409, message=..., motivo="...")
            cuerpo["motivo"] = datos["motivo"]
        return jsonify(cuerpo), e.code

    @app.errorhandler(SQLAlchemyError)
    def _bd(e):
        db.session.rollback()
        app.logger.exception(e)
        return jsonify({"error": "Error al acceder a la base de datos", "codigo": 500}), 500

    @app.errorhandler(Exception)
    def _500(e):
        if isinstance(e, HTTPException):
            return _http(e)
        app.logger.exception(e)
        return jsonify({"error": "Error interno del servidor", "codigo": 500}), 500
