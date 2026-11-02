"""
E01 · POST /api/auth/registro
E02 · POST /api/auth/login
E03 · GET  /api/auth/yo
"""
from flask.views import MethodView
from flask_jwt_extended import create_access_token, current_user, jwt_required
from flask_smorest import Blueprint, abort
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError

from ..extensiones import db
from ..esquemas import LoginSchema, RegistroSchema, TokenSchema, UsuarioSchema
from ..modelos import Usuario
from ..seguridad import ROL_SOCIO, SEGURIDAD

blp = Blueprint("Autenticacion", __name__, url_prefix="/api/auth",
                description="Registro, inicio de sesión y usuario conectado")

DUPLICADO = "El RUT o el correo ya están registrados"


@blp.route("/registro")
class Registro(MethodView):

    @blp.arguments(RegistroSchema, error_status_code=400)
    @blp.response(201, UsuarioSchema)
    @blp.alt_response(400, description="Falta un campo, formato inválido o campo prohibido (id, rol)")
    @blp.alt_response(409, description="USUARIO_DUPLICADO: el RUT o el email ya existen")
    @blp.doc(summary="E01 · Crear cuenta de socio",
             description="Registro abierto. El rol NO se acepta: siempre se crea 'socio'.")
    def post(self, datos):
        rut = datos["rut"].upper()
        email = datos["email"].strip().lower()

        existe = db.session.scalar(
            select(Usuario.id).where(or_(Usuario.rut == rut, Usuario.email == email)))
        if existe:
            abort(409, message=DUPLICADO, motivo="USUARIO_DUPLICADO")

        usuario = Usuario(nombre=datos["nombre"].strip(), rut=rut, email=email,
                          rol=ROL_SOCIO)              # el rol va FIJO en el código
        usuario.set_clave(datos["clave"])
        db.session.add(usuario)
        try:
            db.session.commit()
        except IntegrityError:                         # dos registros iguales al mismo tiempo
            db.session.rollback()
            abort(409, message=DUPLICADO, motivo="USUARIO_DUPLICADO")
        return usuario


@blp.route("/login")
class Login(MethodView):

    @blp.arguments(LoginSchema, error_status_code=400)
    @blp.response(200, TokenSchema)
    @blp.alt_response(400, description="Falta email o clave")
    @blp.alt_response(401, description="Correo o contraseña incorrectos (mismo mensaje siempre)")
    @blp.doc(summary="E02 · Iniciar sesión",
             description="Devuelve el token. Va en la cabecera `Authorization: Bearer <token>`.")
    def post(self, datos):
        usuario = db.session.scalar(
            select(Usuario).where(Usuario.email == datos["email"].strip().lower()))

        # MISMO mensaje si el correo no existe o la clave está mala:
        # así nadie puede averiguar qué correos están registrados.
        if usuario is None or not usuario.verificar_clave(datos["clave"]):
            abort(401, message="Correo o contraseña incorrectos")
        if not usuario.activo:
            abort(401, message="La cuenta está desactivada")

        token = create_access_token(identity=str(usuario.id),
                                    additional_claims={"rol": usuario.rol})
        return {"access_token": token, "token_type": "Bearer",
                "expira_en": 3600, "usuario": usuario}


@blp.route("/yo")
class Yo(MethodView):

    @jwt_required()
    @blp.response(200, UsuarioSchema)
    @blp.alt_response(401, description="Falta el token, es inválido o expiró")
    @blp.doc(summary="E03 · ¿Quién soy?",
             description="Datos del dueño del token. El id es el número de socio.", **SEGURIDAD)
    def get(self):
        return current_user
