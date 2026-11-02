"""
Modelos: cada clase es una tabla (hoja 1-Entidades de la planilla).

El `id` de cada tabla lo asigna la base de datos: el cliente NUNCA lo envía.

Decisiones de borrado (contrato):
    Libro.categoria_id     -> RESTRICT (= PROTECT)  no se borra una categoría con libros
    Copia.libro_id         -> CASCADE               (E08 verifica antes que no haya préstamos)
    Prestamo.copia_id      -> RESTRICT              protege el historial
    Prestamo.socio_id      -> RESTRICT              los usuarios no se borran: se desactivan
    Prestamo.bibliotecario -> RESTRICT
    Multa.prestamo_id      -> RESTRICT              los préstamos nunca se borran
"""
from werkzeug.security import check_password_hash, generate_password_hash

from .extensiones import db
from .tiempo import ahora, hoy


# ---------------------------------------------------------------------------
# Usuario: socios y bibliotecarios
# ---------------------------------------------------------------------------
class Usuario(db.Model):
    __tablename__ = "usuario"

    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    rut = db.Column(db.String(10), nullable=False, unique=True)
    email = db.Column(db.String(120), nullable=False, unique=True)
    # Solo el HASH. Nunca la clave, y nunca sale en una respuesta.
    clave_hash = db.Column(db.String(255), nullable=False)
    rol = db.Column(db.String(20), nullable=False, default="socio")
    activo = db.Column(db.Boolean, nullable=False, default=True)
    creado = db.Column(db.DateTime, nullable=False, default=ahora)

    __table_args__ = (
        db.CheckConstraint("rol IN ('socio', 'bibliotecario')", name="ck_usuario_rol"),
    )

    def set_clave(self, clave):
        self.clave_hash = generate_password_hash(clave)

    def verificar_clave(self, clave):
        # Compara en tiempo constante (no se puede adivinar por lo que tarda)
        return check_password_hash(self.clave_hash, clave)

    def __repr__(self):
        return f"<Usuario {self.email} ({self.rol})>"


# ---------------------------------------------------------------------------
# Categoria
# ---------------------------------------------------------------------------
class Categoria(db.Model):
    __tablename__ = "categoria"

    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(60), nullable=False, unique=True)

    # passive_deletes="all": deja que la BASE decida (RESTRICT) al borrar
    libros = db.relationship("Libro", back_populates="categoria", passive_deletes="all")

    def __repr__(self):
        return f"<Categoria {self.nombre}>"


# ---------------------------------------------------------------------------
# Libro: la obra (no el objeto físico)
# ---------------------------------------------------------------------------
class Libro(db.Model):
    __tablename__ = "libro"

    id = db.Column(db.Integer, primary_key=True)
    titulo = db.Column(db.String(200), nullable=False, index=True)
    autor = db.Column(db.String(120), nullable=False, index=True)
    isbn = db.Column(db.String(13), nullable=False, unique=True)
    anio_publicacion = db.Column(db.Integer, nullable=True)
    categoria_id = db.Column(
        db.Integer,
        db.ForeignKey("categoria.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    categoria = db.relationship("Categoria", back_populates="libros", lazy="joined")
    copias = db.relationship(
        "Copia",
        back_populates="libro",
        lazy="selectin",                 # trae las copias de muchos libros en 1 consulta
        cascade="all, delete-orphan",    # CASCADE: al borrar el libro se van sus copias
        order_by="Copia.id",
    )

    # --- Campos calculados (no son columnas) -----------------------------
    @property
    def copias_total(self):
        return len(self.copias)

    @property
    def copias_disponibles(self):
        return sum(1 for c in self.copias if c.estado == "disponible")

    @property
    def disponible(self):
        return self.copias_disponibles > 0

    def __repr__(self):
        return f"<Libro {self.titulo}>"


# ---------------------------------------------------------------------------
# Copia: el objeto físico, con su etiqueta
# ---------------------------------------------------------------------------
class Copia(db.Model):
    __tablename__ = "copia"

    id = db.Column(db.Integer, primary_key=True)
    libro_id = db.Column(
        db.Integer,
        db.ForeignKey("libro.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    codigo_inventario = db.Column(db.String(30), nullable=False, unique=True)
    estado = db.Column(db.String(12), nullable=False, default="disponible")
    fecha_ingreso = db.Column(db.Date, nullable=False, default=hoy)

    libro = db.relationship("Libro", back_populates="copias")

    __table_args__ = (
        db.CheckConstraint("estado IN ('disponible', 'prestada')", name="ck_copia_estado"),
    )

    def __repr__(self):
        return f"<Copia {self.codigo_inventario} ({self.estado})>"


# ---------------------------------------------------------------------------
# Prestamo
# ---------------------------------------------------------------------------
class Prestamo(db.Model):
    __tablename__ = "prestamo"

    id = db.Column(db.Integer, primary_key=True)
    socio_id = db.Column(
        db.Integer, db.ForeignKey("usuario.id", ondelete="RESTRICT"), nullable=False
    )
    copia_id = db.Column(
        db.Integer, db.ForeignKey("copia.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    bibliotecario_id = db.Column(
        db.Integer, db.ForeignKey("usuario.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    fecha_prestamo = db.Column(db.DateTime, nullable=False)
    fecha_vencimiento = db.Column(db.Date, nullable=False)
    fecha_devolucion = db.Column(db.DateTime, nullable=True)
    estado = db.Column(db.String(10), nullable=False, default="activo")

    # Dos FK a la misma tabla (usuario): hay que decir cuál usa cada relación
    socio = db.relationship("Usuario", foreign_keys=[socio_id], lazy="joined")
    copia = db.relationship("Copia", lazy="joined")
    multa = db.relationship("Multa", back_populates="prestamo", uselist=False, lazy="selectin")

    __table_args__ = (
        db.CheckConstraint("estado IN ('activo', 'devuelto')", name="ck_prestamo_estado"),
        # Acelera "¿cuántos préstamos activos tiene este socio?" (regla de los 3)
        db.Index("ix_prestamo_socio_estado", "socio_id", "estado"),
    )

    # --- Campos calculados ---------------------------------------------------
    @property
    def libro(self):
        return self.copia.libro

    @property
    def atrasado(self):
        """¿Está atrasado AHORA? Solo puede serlo si sigue activo."""
        return self.estado == "activo" and hoy() > self.fecha_vencimiento

    @property
    def dias_atraso(self):
        """Días de atraso: hasta hoy si sigue activo, o hasta la devolución."""
        fin = self.fecha_devolucion.date() if self.fecha_devolucion else hoy()
        return max(0, (fin - self.fecha_vencimiento).days)

    def __repr__(self):
        return f"<Prestamo {self.id} socio={self.socio_id} ({self.estado})>"


# ---------------------------------------------------------------------------
# Multa: nace al devolver con atraso (E14)
# ---------------------------------------------------------------------------
class Multa(db.Model):
    __tablename__ = "multa"

    id = db.Column(db.Integer, primary_key=True)
    prestamo_id = db.Column(
        db.Integer,
        db.ForeignKey("prestamo.id", ondelete="RESTRICT"),
        nullable=False,
        unique=True,                     # 1:1 con el préstamo
    )
    dias_atraso = db.Column(db.Integer, nullable=False)
    monto = db.Column(db.Integer, nullable=False)        # pesos, sin decimales
    estado = db.Column(db.String(10), nullable=False, default="pendiente")
    fecha_pago = db.Column(db.DateTime, nullable=True)

    prestamo = db.relationship("Prestamo", back_populates="multa")

    __table_args__ = (
        db.CheckConstraint("dias_atraso >= 1", name="ck_multa_dias"),
        db.CheckConstraint("monto > 0", name="ck_multa_monto"),
        db.CheckConstraint("estado IN ('pendiente', 'pagada')", name="ck_multa_estado"),
    )

    def __repr__(self):
        return f"<Multa {self.id} ${self.monto} ({self.estado})>"
