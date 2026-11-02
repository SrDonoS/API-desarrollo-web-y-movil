"""Extensiones: se crean sin app y se enlazan en crear_app() con init_app()."""
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_migrate import Migrate
from flask_smorest import Api
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()        # ORM
migrate = Migrate()      # migraciones: flask db upgrade
jwt = JWTManager()       # tokens
cors = CORS()


class ApiBiblioteca(Api):
    """Api de flask-smorest, pero documentando NUESTRO formato de error en Swagger."""

    def __init__(self, *args, **kwargs):
        from .esquemas import ErrorSchema   # import tardío: evita importaciones circulares
        self.ERROR_SCHEMA = ErrorSchema
        super().__init__(*args, **kwargs)


api = ApiBiblioteca()
