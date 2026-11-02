"""La API usa la hora de Chile aunque el servidor (AWS) ande en UTC."""
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from app import crear_app
from app.config import ConfigPruebas
from app.tiempo import ahora, hoy


def test_ahora_usa_la_zona_configurada():
    app = crear_app(ConfigPruebas)
    with app.app_context():
        esperado = datetime.now(ZoneInfo("America/Santiago")).replace(tzinfo=None)
        assert abs(ahora() - esperado) < timedelta(seconds=5)
        assert ahora().microsecond == 0 and ahora().tzinfo is None
        assert hoy() == ahora().date()


def test_otra_zona_cambia_la_hora():
    class ConfigTokio(ConfigPruebas):
        ZONA_HORARIA = "Asia/Tokyo"

    app = crear_app(ConfigTokio)
    with app.app_context():
        esperado = datetime.now(ZoneInfo("Asia/Tokyo")).replace(tzinfo=None)
        assert abs(ahora() - esperado) < timedelta(seconds=5)
