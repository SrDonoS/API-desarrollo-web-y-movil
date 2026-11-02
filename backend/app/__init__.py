"""
Fábrica de la aplicación: crear_app() arma la API completa.

    python run.py                  (desarrollo)
    gunicorn -w 3 run:app          (producción, AWS)
"""
from flask import Flask, redirect

from .config import Config
from .extensiones import api, cors, db, jwt, migrate


def crear_app(config=Config):
    app = Flask(__name__)
    app.config.from_object(config)
    _verificar_config(app)

    # JSON legible: "Pérez" en vez de "Pérez", y los campos en el orden del esquema
    app.json.ensure_ascii = False
    app.json.sort_keys = False

    if app.config["SQLALCHEMY_DATABASE_URI"].startswith("mysql"):
        app.config.setdefault("SQLALCHEMY_ENGINE_OPTIONS", {
            # MySQL (y RDS) cortan las conexiones inactivas: pre_ping las revisa antes de usarlas
            "pool_pre_ping": True,
            "pool_recycle": 280,
            # Cada consulta ve lo último confirmado. Clave para la regla de los 3 préstamos:
            # tras esperar el bloqueo del socio, el conteo ve los préstamos recién creados.
            # (Con el REPEATABLE READ por defecto, el conteo vería una "foto" vieja).
            "isolation_level": "READ COMMITTED",
        })

    # --- Extensiones --------------------------------------------------------
    db.init_app(app)
    migrate.init_app(app, db, compare_type=True)
    jwt.init_app(app)
    cors.init_app(app, resources={r"/api/*": {"origins": app.config["CORS_ORIGINS"]}})
    api.init_app(app)

    from . import modelos  # noqa: F401  (registra las tablas antes de migrar)

    _activar_fk_sqlite()
    _configurar_jwt(app)

    # --- Rutas (blueprints) -------------------------------------------------
    from .rutas import auth, categorias, libros, mis_prestamos, multas, prestamos
    for modulo in (auth, libros, categorias, prestamos, mis_prestamos, multas):
        api.register_blueprint(modulo.blp)

    # --- Errores y comandos -------------------------------------------------
    from .comandos import registrar_comandos
    from .errores import registrar_errores
    registrar_errores(app)
    registrar_comandos(app)

    @app.get("/")
    def indice():
        return redirect("/docs")

    return app


def _verificar_config(app):
    """Falla al tiro y con un mensaje claro si falta algo del .env."""
    faltan = [v for v in ("SQLALCHEMY_DATABASE_URI", "JWT_SECRET_KEY") if not app.config.get(v)]
    if faltan:
        nombres = {"SQLALCHEMY_DATABASE_URI": "DATABASE_URL", "JWT_SECRET_KEY": "JWT_SECRET_KEY"}
        raise RuntimeError(
            "Falta configurar: " + ", ".join(nombres[f] for f in faltan) +
            ". ¿Copiaste .env.example como .env dentro de backend/?")
    if len(app.config["JWT_SECRET_KEY"]) < 32:
        raise RuntimeError("JWT_SECRET_KEY debe tener al menos 32 caracteres.")


_FK_SQLITE_ACTIVADO = False


def _activar_fk_sqlite():
    """SQLite (pruebas) no revisa las FK salvo que se active. MySQL siempre las revisa."""
    global _FK_SQLITE_ACTIVADO
    if _FK_SQLITE_ACTIVADO:
        return
    _FK_SQLITE_ACTIVADO = True
    import sqlite3

    from sqlalchemy import event
    from sqlalchemy.engine import Engine

    @event.listens_for(Engine, "connect")
    def _fk(conexion, _registro):
        if isinstance(conexion, sqlite3.Connection):
            cursor = conexion.cursor()
            cursor.execute("PRAGMA foreign_keys = ON")
            cursor.close()


def _configurar_jwt(app):
    """Errores de token con el formato de la API (siempre 401)."""
    from flask import jsonify

    from .modelos import Usuario

    def _error(mensaje):
        return jsonify({"error": mensaje, "codigo": 401}), 401

    @jwt.user_identity_loader
    def _identidad(usuario_id):
        return str(usuario_id)

    @jwt.user_lookup_loader
    def _cargar_usuario(_cabecera, datos):
        # current_user en las vistas. Si la cuenta se desactivó, el token deja de servir.
        usuario = db.session.get(Usuario, int(datos["sub"]))
        return usuario if usuario is not None and usuario.activo else None

    @jwt.unauthorized_loader
    def _falta_token(_motivo):
        return _error("Falta el token. Envíe la cabecera Authorization: Bearer <token>")

    @jwt.invalid_token_loader
    def _token_invalido(_motivo):
        return _error("El token no es válido o expiró")

    @jwt.expired_token_loader
    def _token_vencido(_cabecera, _datos):
        return _error("El token no es válido o expiró")

    @jwt.user_lookup_error_loader
    def _sin_usuario(_cabecera, _datos):
        return _error("La cuenta asociada al token no existe o está desactivada")
