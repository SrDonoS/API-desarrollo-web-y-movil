"""
La hora oficial de la API: la de Chile (o la de ZONA_HORARIA).

Los servidores de AWS andan en UTC. Si usáramos datetime.now() a secas,
un préstamo hecho a las 22:00 en Chile quedaría registrado al día siguiente
y las multas se calcularían corridas. Por eso TODO el código usa ahora() y hoy().

Las fechas se guardan "naive" (sin zona) en la base, ya convertidas a hora local.
"""
from datetime import date, datetime
from zoneinfo import ZoneInfo

from flask import current_app, has_app_context

ZONA_POR_DEFECTO = "America/Santiago"


def _zona():
    nombre = ZONA_POR_DEFECTO
    if has_app_context():
        nombre = current_app.config.get("ZONA_HORARIA", ZONA_POR_DEFECTO)
    return ZoneInfo(nombre)


def ahora() -> datetime:
    """Fecha y hora local, sin microsegundos (así sale en el JSON: 2026-10-13T10:30:00)."""
    return datetime.now(_zona()).replace(tzinfo=None, microsecond=0)


def hoy() -> date:
    return ahora().date()
