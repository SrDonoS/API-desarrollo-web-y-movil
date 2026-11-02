"""
Fixtures de pytest.

Por defecto las pruebas usan SQLite en memoria (rápido, no necesitas MySQL).
Para probar contra MySQL de verdad (recomendado antes de subir a AWS):

    # en el .env, o en la terminal:
    TEST_DATABASE_URL=mysql+pymysql://biblio_app:cambia-esta-clave@localhost:3306/biblioteca_test?charset=utf8mb4
    pytest -v

⚠️  La base de TEST_DATABASE_URL se BORRA entera en cada corrida. Nunca uses la de desarrollo.
"""
import pytest

from app import crear_app
from app.config import ConfigPruebas
from app.extensiones import db


@pytest.fixture(scope="module")
def app():
    aplicacion = crear_app(ConfigPruebas)
    with aplicacion.app_context():
        db.drop_all()
        db.create_all()
    yield aplicacion
    with aplicacion.app_context():
        db.session.remove()
        db.drop_all()
        db.engine.dispose()


@pytest.fixture(scope="module")
def client(app):
    return app.test_client()


@pytest.fixture(scope="module")
def estado():
    """Datos que se van pasando de una prueba a la siguiente (tokens, ids…)."""
    return {}


@pytest.fixture(scope="module")
def probadas():
    """(endpoint, código) de cada respuesta verificada. La última prueba revisa que estén las 68."""
    return set()
