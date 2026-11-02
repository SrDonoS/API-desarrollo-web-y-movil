"""
Autenticación (401) y autorización (403).

  401  "no sé quién eres"            -> falta el token, es falso o expiró
  403  "sé quién eres, no te toca"   -> eres socio y esto es de bibliotecario

La autenticación simple la da @jwt_required(). Aquí vive el decorador de rol.
"""
from functools import wraps

from flask_jwt_extended import get_jwt, verify_jwt_in_request
from flask_smorest import abort

ROL_SOCIO = "socio"
ROL_BIBLIOTECARIO = "bibliotecario"

# Para @blp.doc(**SEGURIDAD): Swagger le pone candado al endpoint.
SEGURIDAD = {"security": [{"bearerAuth": []}]}


def bibliotecario_requerido(fn):
    """Exige token válido (si no, 401) y rol bibliotecario (si no, 403)."""

    @wraps(fn)
    def envoltorio(*args, **kwargs):
        verify_jwt_in_request()                          # 1) AUTENTICACIÓN -> 401
        if get_jwt().get("rol") != ROL_BIBLIOTECARIO:    # 2) AUTORIZACIÓN  -> 403
            abort(403, message="Esta operación requiere rol de bibliotecario")
        return fn(*args, **kwargs)

    return envoltorio
