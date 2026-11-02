"""
Configuración de la API.

Todo lo que cambia entre tu compu y AWS sale de VARIABLES DE ENTORNO
(archivo .env en desarrollo; variables del servicio en el servidor).
El código es el mismo en todas partes: solo cambian las variables.
"""
import os
from datetime import timedelta

from dotenv import load_dotenv

# backend/  (la carpeta donde vive run.py y el .env)
RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# `flask ...` lee el .env solo, pero `python run.py` arma la config ANTES.
# Por eso se carga aquí, explícitamente. No pisa variables ya definidas.
load_dotenv(os.path.join(RAIZ, ".env"))


def _entero(nombre, defecto):
    return int(os.environ.get(nombre, defecto))


class Config:
    # --- Base de datos -------------------------------------------------------
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = os.environ.get("SQL_ECHO", "0") == "1"

    # --- JWT -------------------------------------------------------------------
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)      # contrato: el token dura 1 hora
    JWT_TOKEN_LOCATION = ["headers"]
    JWT_HEADER_NAME = "Authorization"
    JWT_HEADER_TYPE = "Bearer"

    # --- Reglas del negocio (contrato) ---------------------------------------
    MAX_PRESTAMOS_ACTIVOS = _entero("MAX_PRESTAMOS_ACTIVOS", 3)
    DIAS_PRESTAMO = _entero("DIAS_PRESTAMO", 14)
    MULTA_POR_DIA = _entero("MULTA_POR_DIA", 500)
    ZONA_HORARIA = os.environ.get("ZONA_HORARIA", "America/Santiago")

    # --- CORS --------------------------------------------------------------------
    CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "*")

    # --- OpenAPI / Swagger -------------------------------------------------------
    API_TITLE = "API Biblioteca Comunitaria"
    API_VERSION = "1.0"
    OPENAPI_VERSION = "3.0.3"
    OPENAPI_URL_PREFIX = "/"
    OPENAPI_JSON_PATH = "openapi.json"
    OPENAPI_SWAGGER_UI_PATH = "/docs"
    OPENAPI_SWAGGER_UI_URL = "https://cdn.jsdelivr.net/npm/swagger-ui-dist/"
    API_SPEC_OPTIONS = {
        "info": {
            "description": (
                "API de la Biblioteca Comunitaria. Implementa al pie de la letra la "
                "planilla de especificación (16 endpoints, E01 a E16).\n\n"
                "### Cómo probar los endpoints con candado\n"
                "1. `POST /api/auth/login` → *Try it out* (bibliotecario de prueba: "
                "`biblio@biblioteca.cl` / `biblio1234`).\n"
                "2. Copia el `access_token`.\n"
                "3. Botón **Authorize** (arriba a la derecha) → pégalo.\n\n"
                "Formato de error: `{\"error\", \"codigo\"}` (+ `detalles` en los 400, "
                "+ `motivo` en los 409)."
            ),
        },
        "components": {
            "securitySchemes": {
                "bearerAuth": {"type": "http", "scheme": "bearer", "bearerFormat": "JWT"}
            }
        },
        "tags": [
            {"name": "Autenticacion", "description": "E01–E03 · Registro, login y usuario conectado"},
            {"name": "Libros", "description": "E04–E09 · Catálogo (CRUD completo) y copias físicas"},
            {"name": "Categorias", "description": "E10–E11"},
            {"name": "Prestamos", "description": "E12–E14 · Solo bibliotecario"},
            {"name": "MisPrestamos", "description": "E15 · Los préstamos del dueño del token"},
            {"name": "Multas", "description": "E16 · Solo bibliotecario"},
        ],
    }


class ConfigPruebas(Config):
    """Config de pytest: SQLite en memoria, o TEST_DATABASE_URL si se define (MySQL)."""

    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.environ.get("TEST_DATABASE_URL", "sqlite://")
    JWT_SECRET_KEY = "clave-solo-para-pruebas-0123456789-abcdefghijklmnop"
    SQLALCHEMY_ECHO = False
    # Las reglas fijas del contrato, aunque el .env diga otra cosa
    MAX_PRESTAMOS_ACTIVOS = 3
    DIAS_PRESTAMO = 14
    MULTA_POR_DIA = 500
