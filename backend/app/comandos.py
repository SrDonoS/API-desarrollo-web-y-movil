"""
Comandos de consola:

    flask --app run init-db              migraciones + datos de prueba (DESARROLLO)
    flask --app run init-db --sin-datos  solo migraciones
    flask --app run crear-bibliotecario  crea un bibliotecario pidiendo los datos (PRODUCCIÓN)

Los bibliotecarios NO se crean por la API: el registro (E01) siempre crea socios.
"""
import click
from flask.cli import with_appcontext
from flask_migrate import upgrade
from marshmallow import ValidationError
from sqlalchemy import or_, select

from .esquemas import RegistroSchema
from .extensiones import db
from .modelos import Categoria, Copia, Libro, Usuario
from .seguridad import ROL_BIBLIOTECARIO, ROL_SOCIO

# (nombre, rut, email, clave, rol) — SOLO para desarrollo
USUARIOS_PRUEBA = [
    ("Marta Fuentes", "11111111-1", "biblio@biblioteca.cl", "biblio1234", ROL_BIBLIOTECARIO),
    ("Ana Rojas Pérez", "12345678-5", "ana.rojas@correo.cl", "clave-segura-123", ROL_SOCIO),
    ("Pedro Soto", "9876543-3", "pedro.soto@correo.cl", "clave-segura-123", ROL_SOCIO),
]

CATEGORIAS = ["Novela", "Poesía", "Infantil", "Ciencia", "Historia"]

# (título, autor, isbn, año, categoría, cantidad de copias)
LIBROS = [
    ("Cien años de soledad", "Gabriel García Márquez", "9780307474728", 1967, "Novela", 3),
    ("La casa de los espíritus", "Isabel Allende", "9780000000101", 1982, "Novela", 2),
    ("Hijo de ladrón", "Manuel Rojas", "9780000000102", 1951, "Novela", 2),
    ("Veinte poemas de amor y una canción desesperada", "Pablo Neruda", "9780000000103",
     1924, "Poesía", 2),
    ("Desolación", "Gabriela Mistral", "9780000000104", 1922, "Poesía", 1),
    ("Papelucho", "Marcela Paz", "9780000000105", 1947, "Infantil", 2),
    ("El principito", "Antoine de Saint-Exupéry", "9780000000106", 1943, "Infantil", 2),
    ("Breve historia del tiempo", "Stephen Hawking", "9780000000107", 1988, "Ciencia", 1),
]


def _crear_usuario(nombre, rut, email, clave, rol):
    u = Usuario(nombre=nombre, rut=rut.upper(), email=email.lower(), rol=rol)
    u.set_clave(clave)
    db.session.add(u)
    return u


def _cargar_datos_prueba():
    creados = 0
    for nombre, rut, email, clave, rol in USUARIOS_PRUEBA:
        if db.session.scalar(select(Usuario.id).where(Usuario.email == email)) is None:
            _crear_usuario(nombre, rut, email, clave, rol)
            creados += 1
    db.session.commit()
    if creados:
        click.echo(f"👤 {creados} usuarios de prueba:")
        for nombre, _, email, clave, rol in USUARIOS_PRUEBA:
            click.echo(f"     {rol:<14} {email:<24} / {clave}")

    if db.session.scalar(select(Categoria.id).limit(1)) is not None:
        click.echo("📚 El catálogo ya tenía datos: no se tocó.")
        return

    categorias = {}
    for nombre in CATEGORIAS:
        categorias[nombre] = Categoria(nombre=nombre)
        db.session.add(categorias[nombre])

    numero = 0
    for titulo, autor, isbn, anio, cat, n_copias in LIBROS:
        libro = Libro(titulo=titulo, autor=autor, isbn=isbn, anio_publicacion=anio,
                      categoria=categorias[cat])
        db.session.add(libro)
        for _ in range(n_copias):
            numero += 1
            libro.copias.append(Copia(codigo_inventario=f"LIB-{numero:06d}", estado="disponible"))
    db.session.commit()
    click.echo(f"📚 {len(CATEGORIAS)} categorías, {len(LIBROS)} libros y {numero} copias.")


@click.command("init-db")
@click.option("--sin-datos", is_flag=True, help="Solo aplica las migraciones.")
@with_appcontext
def init_db(sin_datos):
    """Aplica las migraciones y (en desarrollo) carga datos de prueba."""
    upgrade()
    click.echo("🗃️  Tablas al día (migraciones aplicadas).")
    if not sin_datos:
        _cargar_datos_prueba()
    click.echo("✅ Listo. Corre: python run.py  y abre http://127.0.0.1:5000/docs")


@click.command("crear-bibliotecario")
@click.option("--nombre", prompt="Nombre completo")
@click.option("--rut", prompt="RUT (12345678-9)")
@click.option("--email", prompt="Email")
@click.option("--clave", prompt="Clave (mín. 8)", hide_input=True, confirmation_prompt=True)
@with_appcontext
def crear_bibliotecario(nombre, rut, email, clave):
    """Crea un bibliotecario. Es la única forma de crear uno (la API solo crea socios)."""
    try:
        datos = RegistroSchema().load(
            {"nombre": nombre, "rut": rut, "email": email, "clave": clave})
    except ValidationError as err:
        for campo, problemas in err.messages.items():
            click.echo(f"❌ {campo}: {' '.join(problemas)}")
        raise SystemExit(1)

    ya = db.session.scalar(select(Usuario.id).where(or_(
        Usuario.rut == datos["rut"].upper(), Usuario.email == datos["email"].lower())))
    if ya:
        click.echo("❌ Ya existe un usuario con ese RUT o email.")
        raise SystemExit(1)

    u = _crear_usuario(datos["nombre"].strip(), datos["rut"], datos["email"], datos["clave"],
                       ROL_BIBLIOTECARIO)
    db.session.commit()
    click.echo(f"✅ Bibliotecario creado: {u.email} (id {u.id})")


def registrar_comandos(app):
    app.cli.add_command(init_db)
    app.cli.add_command(crear_bibliotecario)
