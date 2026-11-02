"""
Pruebas del CONTRATO: una por cada fila de la hoja 4-Salidas (68 respuestas).

Las pruebas van en orden y cuentan una historia, igual que el plan de pruebas de la guía:
registro -> login -> categorías -> libros -> copias -> préstamos -> devolución -> multa -> pago.

    pytest -v
"""
from datetime import timedelta

from app.extensiones import db
from app.modelos import Prestamo, Usuario
from app.tiempo import hoy

from .contrato import SALIDAS

ANA = {"nombre": "Ana Rojas Pérez", "rut": "12345678-5",
       "email": "ana.rojas@correo.cl", "clave": "clave-segura-123"}
LIBRO = {"titulo": "Cien años de soledad", "autor": "Gabriel García Márquez",
         "isbn": "9780307474728", "anio_publicacion": 1967}


def con_token(token):
    return {"Authorization": f"Bearer {token}"}


def verificar(probadas, endpoint, esperado, resp, motivo=None):
    """Revisa código, formato de error y motivo. Anota la fila del contrato como probada."""
    cuerpo = resp.get_json(silent=True)
    assert resp.status_code == esperado, f"{endpoint}: esperaba {esperado}, llegó {resp.status_code} {cuerpo}"
    if esperado >= 400:
        assert cuerpo["codigo"] == esperado and isinstance(cuerpo["error"], str), cuerpo
        if esperado == 400 and "detalles" in cuerpo:
            assert isinstance(cuerpo["detalles"], dict)
    if motivo is not None:
        assert cuerpo.get("motivo") == motivo, cuerpo
    probadas.add((endpoint, esperado))
    return cuerpo


# ---------------------------------------------------------------------------
# E01 · Registro
# ---------------------------------------------------------------------------
def test_e01_registro(app, client, estado, probadas):
    with app.app_context():                     # el bibliotecario NO se crea por la API
        b = Usuario(nombre="Marta Fuentes", rut="11111111-1", email="biblio@biblioteca.cl",
                    rol="bibliotecario")
        b.set_clave("biblio1234")
        inactivo = Usuario(nombre="Socio Inactivo", rut="5555555-5",
                           email="inactivo@correo.cl", rol="socio", activo=False)
        inactivo.set_clave("clave-1234")
        db.session.add_all([b, inactivo])
        db.session.commit()
        estado["biblio_id"] = b.id

    cuerpo = verificar(probadas, "E01", 201, client.post("/api/auth/registro", json=ANA))
    assert cuerpo["rol"] == "socio" and "clave" not in cuerpo and "clave_hash" not in cuerpo
    assert set(cuerpo) == {"id", "nombre", "rut", "email", "rol", "activo", "creado"}
    assert len(cuerpo["creado"]) == 19                       # 2026-10-13T10:30:00
    estado["ana_id"] = cuerpo["id"]

    verificar(probadas, "E01", 400, client.post("/api/auth/registro",
              json=dict(ANA, rut="12.345.678-5", email="otra@correo.cl")))
    r = verificar(probadas, "E01", 400, client.post("/api/auth/registro",
                  json=dict(ANA, rol="bibliotecario", rut="22222222-2", email="z@correo.cl")))
    assert "rol" in r["detalles"]
    verificar(probadas, "E01", 400, client.post("/api/auth/registro",
              json=dict(ANA, clave="corta", rut="22222222-2", email="z@correo.cl")))
    verificar(probadas, "E01", 409, client.post("/api/auth/registro", json=ANA),
              "USUARIO_DUPLICADO")
    # mismo email con mayúsculas = mismo usuario
    verificar(probadas, "E01", 409, client.post("/api/auth/registro",
              json=dict(ANA, rut="33333333-3", email="ANA.ROJAS@correo.cl")), "USUARIO_DUPLICADO")

    # Pedro: lo usaremos para la regla de los 3 préstamos
    cuerpo = verificar(probadas, "E01", 201, client.post("/api/auth/registro", json={
        "nombre": "Pedro Soto", "rut": "9876543-k", "email": "pedro.soto@correo.cl",
        "clave": "clave-segura-123"}))
    assert cuerpo["rut"] == "9876543-K"                      # K mayúscula
    estado["pedro_id"] = cuerpo["id"]


# ---------------------------------------------------------------------------
# E02 · Login
# ---------------------------------------------------------------------------
def test_e02_login(client, estado, probadas):
    def login(email, clave):
        return client.post("/api/auth/login", json={"email": email, "clave": clave})

    cuerpo = verificar(probadas, "E02", 200, login(ANA["email"], ANA["clave"]))
    assert cuerpo["token_type"] == "Bearer" and cuerpo["expira_en"] == 3600
    assert cuerpo["usuario"]["id"] == estado["ana_id"]
    estado["t_ana"] = cuerpo["access_token"]
    estado["t_biblio"] = login("biblio@biblioteca.cl", "biblio1234").get_json()["access_token"]
    estado["t_pedro"] = login("pedro.soto@correo.cl", "clave-segura-123").get_json()["access_token"]

    verificar(probadas, "E02", 400, client.post("/api/auth/login", json={"email": ANA["email"]}))
    a = verificar(probadas, "E02", 401, login(ANA["email"], "clave-mala"))
    b = verificar(probadas, "E02", 401, login("noexiste@correo.cl", "clave-mala"))
    assert a["error"] == b["error"], "el mensaje debe ser el MISMO"
    verificar(probadas, "E02", 401, login("inactivo@correo.cl", "clave-1234"))


# ---------------------------------------------------------------------------
# E03 · Yo
# ---------------------------------------------------------------------------
def test_e03_yo(client, estado, probadas):
    cuerpo = verificar(probadas, "E03", 200, client.get("/api/auth/yo",
                                                        headers=con_token(estado["t_ana"])))
    assert cuerpo["id"] == estado["ana_id"] and cuerpo["rol"] == "socio"
    verificar(probadas, "E03", 401, client.get("/api/auth/yo"))
    falso = estado["t_ana"][:-4] + "abcd"
    verificar(probadas, "E03", 401, client.get("/api/auth/yo", headers=con_token(falso)))


# ---------------------------------------------------------------------------
# E10 / E11 · Categorías
# ---------------------------------------------------------------------------
def test_e11_crear_categoria(client, estado, probadas):
    tb, ta = con_token(estado["t_biblio"]), con_token(estado["t_ana"])
    cuerpo = verificar(probadas, "E11", 201, client.post("/api/categorias",
                       json={"nombre": "Novela"}, headers=tb))
    assert cuerpo["total_libros"] == 0
    estado["cat_id"] = cuerpo["id"]
    verificar(probadas, "E11", 201, client.post("/api/categorias",
              json={"nombre": "Historia"}, headers=tb))
    verificar(probadas, "E11", 400, client.post("/api/categorias", json={"nombre": "No"},
                                                headers=tb))
    verificar(probadas, "E11", 401, client.post("/api/categorias", json={"nombre": "Poesía"}))
    verificar(probadas, "E11", 403, client.post("/api/categorias", json={"nombre": "Poesía"},
                                                headers=ta))
    verificar(probadas, "E11", 409, client.post("/api/categorias", json={"nombre": "NOVELA"},
                                                headers=tb), "CATEGORIA_DUPLICADA")


# ---------------------------------------------------------------------------
# E06 · Crear libro
# ---------------------------------------------------------------------------
def test_e06_crear_libro(client, estado, probadas):
    tb = con_token(estado["t_biblio"])
    libro = dict(LIBRO, categoria_id=estado["cat_id"])
    r = client.post("/api/libros", json=libro, headers=tb)
    cuerpo = verificar(probadas, "E06", 201, r)
    assert r.headers["Location"] == f"/api/libros/{cuerpo['id']}"
    assert cuerpo["copias_total"] == 0 and cuerpo["disponible"] is False
    assert cuerpo["categoria"] == {"id": estado["cat_id"], "nombre": "Novela"}
    estado["libro_id"] = cuerpo["id"]
    estado["libro"] = libro

    verificar(probadas, "E06", 400, client.post("/api/libros",
              json=dict(libro, isbn="978-0307"), headers=tb))
    verificar(probadas, "E06", 400, client.post("/api/libros",
              json=dict(libro, isbn="123456789X", categoria_id=999), headers=tb))
    verificar(probadas, "E06", 400, client.post("/api/libros",
              json=dict(libro, id=5, isbn="123456789X"), headers=tb))
    verificar(probadas, "E06", 401, client.post("/api/libros", json=libro))
    verificar(probadas, "E06", 403, client.post("/api/libros", json=libro,
                                                headers=con_token(estado["t_ana"])))
    verificar(probadas, "E06", 409, client.post("/api/libros", json=libro, headers=tb),
              "ISBN_DUPLICADO")

    otro = {"titulo": "Libro sin copias", "autor": "Autora X", "isbn": "123456789X",
            "categoria_id": estado["cat_id"]}
    estado["libro2_id"] = client.post("/api/libros", json=otro, headers=tb).get_json()["id"]


# ---------------------------------------------------------------------------
# E09 · Copias
# ---------------------------------------------------------------------------
def test_e09_copias(client, estado, probadas):
    tb, lid = con_token(estado["t_biblio"]), estado["libro_id"]
    ids = []
    for n in range(1, 6):
        r = client.post(f"/api/libros/{lid}/copias",
                        json={"codigo_inventario": f"LIB-00003{n}"}, headers=tb)
        cuerpo = verificar(probadas, "E09", 201, r)
        assert cuerpo["estado"] == "disponible" and cuerpo["libro_id"] == lid
        assert r.headers["Location"] == f"/api/libros/{lid}"
        ids.append(cuerpo["id"])
    estado["copias"] = ids

    verificar(probadas, "E09", 400, client.post(f"/api/libros/{lid}/copias",
              json={"codigo_inventario": "lib-1"}, headers=tb))
    verificar(probadas, "E09", 401, client.post(f"/api/libros/{lid}/copias",
              json={"codigo_inventario": "LIB-9"}))
    verificar(probadas, "E09", 403, client.post(f"/api/libros/{lid}/copias",
              json={"codigo_inventario": "LIB-9"}, headers=con_token(estado["t_ana"])))
    verificar(probadas, "E09", 404, client.post("/api/libros/9999/copias",
              json={"codigo_inventario": "LIB-9"}, headers=tb))
    verificar(probadas, "E09", 409, client.post(f"/api/libros/{lid}/copias",
              json={"codigo_inventario": "LIB-000031"}, headers=tb), "CODIGO_DUPLICADO")


# ---------------------------------------------------------------------------
# E04 / E05 / E10 · Lecturas del catálogo
# ---------------------------------------------------------------------------
def test_e04_e05_e10_catalogo(client, estado, probadas):
    ta = con_token(estado["t_ana"])
    cuerpo = verificar(probadas, "E04", 200, client.get(
        "/api/libros?buscar=soledad&disponible=true", headers=ta))
    assert cuerpo["total"] == 1 and cuerpo["items"][0]["copias_disponibles"] == 5
    assert set(cuerpo) == {"total", "pagina", "tam", "paginas", "items"}
    cuerpo = client.get("/api/libros?disponible=false", headers=ta).get_json()
    assert [l["id"] for l in cuerpo["items"]] == [estado["libro2_id"]]
    cuerpo = client.get("/api/libros?categoria=9999", headers=ta).get_json()
    assert cuerpo["total"] == 0                               # filtrar no es error
    cuerpo = client.get("/api/libros?tam=1&pagina=2", headers=ta).get_json()
    assert cuerpo["paginas"] == 2 and len(cuerpo["items"]) == 1
    verificar(probadas, "E04", 400, client.get("/api/libros?tam=51", headers=ta))
    verificar(probadas, "E04", 400, client.get("/api/libros?pagina=0", headers=ta))
    verificar(probadas, "E04", 401, client.get("/api/libros"))

    cuerpo = verificar(probadas, "E05", 200, client.get(f"/api/libros/{estado['libro_id']}",
                                                        headers=ta))
    assert len(cuerpo["copias"]) == 5
    assert set(cuerpo["copias"][0]) == {"id", "codigo_inventario", "estado"}   # sin socio
    verificar(probadas, "E05", 401, client.get(f"/api/libros/{estado['libro_id']}"))
    verificar(probadas, "E05", 404, client.get("/api/libros/9999", headers=ta))

    cuerpo = verificar(probadas, "E10", 200, client.get("/api/categorias", headers=ta))
    assert [c["nombre"] for c in cuerpo] == ["Historia", "Novela"]
    assert cuerpo[1]["total_libros"] == 2
    verificar(probadas, "E10", 401, client.get("/api/categorias"))


# ---------------------------------------------------------------------------
# E07 · PUT
# ---------------------------------------------------------------------------
def test_e07_reemplazar_libro(client, estado, probadas):
    tb, lid, libro = con_token(estado["t_biblio"]), estado["libro_id"], estado["libro"]
    sin_anio = {k: v for k, v in libro.items() if k != "anio_publicacion"}
    cuerpo = verificar(probadas, "E07", 200, client.put(f"/api/libros/{lid}", json=sin_anio,
                                                        headers=tb))
    assert cuerpo["anio_publicacion"] is None                 # PUT reemplaza TODO
    verificar(probadas, "E07", 200, client.put(f"/api/libros/{lid}", json=libro, headers=tb))
    verificar(probadas, "E07", 400, client.put(f"/api/libros/{lid}",
              json={"titulo": "Solo el título"}, headers=tb))
    verificar(probadas, "E07", 401, client.put(f"/api/libros/{lid}", json=libro))
    verificar(probadas, "E07", 403, client.put(f"/api/libros/{lid}", json=libro,
                                               headers=con_token(estado["t_ana"])))
    verificar(probadas, "E07", 404, client.put("/api/libros/9999", json=libro, headers=tb))
    verificar(probadas, "E07", 409, client.put(f"/api/libros/{estado['libro2_id']}",
              json=libro, headers=tb), "ISBN_DUPLICADO")


# ---------------------------------------------------------------------------
# E12 · Préstamos
# ---------------------------------------------------------------------------
def test_e12_prestamos(app, client, estado, probadas):
    tb = con_token(estado["t_biblio"])
    c1, c2, c3, c4, c5 = estado["copias"]
    ana, pedro = estado["ana_id"], estado["pedro_id"]

    def prestar(datos, headers=tb):
        return client.post("/api/prestamos", json=datos, headers=headers)

    cuerpo = verificar(probadas, "E12", 201, prestar({"socio_id": ana, "copia_id": c1}))
    with app.app_context():
        assert cuerpo["fecha_vencimiento"] == (hoy() + timedelta(days=14)).isoformat()
    assert cuerpo["estado"] == "activo" and cuerpo["multa"] is None
    assert cuerpo["socio"]["id"] == ana and cuerpo["copia"]["id"] == c1
    assert cuerpo["libro"]["titulo"] == "Cien años de soledad"
    estado["p_ana"] = cuerpo["id"]

    verificar(probadas, "E12", 400, prestar({"socio_id": ana}))
    verificar(probadas, "E12", 400, prestar({"socio_id": ana, "copia_id": c2,
                                             "fecha_vencimiento": "2030-01-01"}))
    verificar(probadas, "E12", 400, prestar({"socio_id": ana, "copia_id": str(c2)}))
    verificar(probadas, "E12", 400, prestar({"socio_id": 9999, "copia_id": c2}))
    verificar(probadas, "E12", 400, prestar({"socio_id": estado["biblio_id"], "copia_id": c2}))
    verificar(probadas, "E12", 400, prestar({"socio_id": ana, "copia_id": 9999}))
    verificar(probadas, "E12", 401, prestar({"socio_id": ana, "copia_id": c2}, headers={}))
    verificar(probadas, "E12", 403, prestar({"socio_id": ana, "copia_id": c2},
                                            headers=con_token(estado["t_ana"])))
    verificar(probadas, "E12", 409, prestar({"socio_id": pedro, "copia_id": c1}),
              "COPIA_NO_DISPONIBLE")

    estado["p_pedro"] = []
    for c in (c2, c3, c4):
        estado["p_pedro"].append(verificar(probadas, "E12", 201,
                                           prestar({"socio_id": pedro, "copia_id": c}))["id"])
    verificar(probadas, "E12", 409, prestar({"socio_id": pedro, "copia_id": c5}),
              "LIMITE_PRESTAMOS")
    # 4.º préstamo con copia ocupada: gana LIMITE (se revisa primero, según el contrato)
    verificar(probadas, "E12", 409, prestar({"socio_id": pedro, "copia_id": c1}),
              "LIMITE_PRESTAMOS")

    detalle = client.get(f"/api/libros/{estado['libro_id']}", headers=tb).get_json()
    assert detalle["copias_disponibles"] == 1


# ---------------------------------------------------------------------------
# E08 · DELETE
# ---------------------------------------------------------------------------
def test_e08_eliminar_libro(client, estado, probadas):
    tb, l2 = con_token(estado["t_biblio"]), estado["libro2_id"]
    verificar(probadas, "E08", 409, client.delete(f"/api/libros/{estado['libro_id']}",
                                                  headers=tb), "LIBRO_CON_PRESTAMOS")
    verificar(probadas, "E08", 401, client.delete(f"/api/libros/{l2}"))
    verificar(probadas, "E08", 403, client.delete(f"/api/libros/{l2}",
                                                  headers=con_token(estado["t_ana"])))
    client.post(f"/api/libros/{l2}/copias", json={"codigo_inventario": "LIB-000099"}, headers=tb)
    r = client.delete(f"/api/libros/{l2}", headers=tb)
    verificar(probadas, "E08", 204, r)
    assert r.data == b""                                       # 204 = sin cuerpo
    verificar(probadas, "E08", 404, client.delete(f"/api/libros/{l2}", headers=tb))


# ---------------------------------------------------------------------------
# E14 · Devolución (y multa)
# ---------------------------------------------------------------------------
def test_e14_devolucion(app, client, estado, probadas):
    tb, pid = con_token(estado["t_biblio"]), estado["p_ana"]
    with app.app_context():                    # simulamos que venció hace 3 días
        p = db.session.get(Prestamo, pid)
        p.fecha_vencimiento = hoy() - timedelta(days=3)
        db.session.commit()

    cuerpo = client.get("/api/prestamos?atrasado=true", headers=tb).get_json()
    assert cuerpo["total"] == 1 and cuerpo["items"][0]["atrasado"] is True
    assert cuerpo["items"][0]["dias_atraso"] == 3

    cuerpo = verificar(probadas, "E14", 200, client.post(f"/api/prestamos/{pid}/devolucion",
                                                         headers=tb))
    assert cuerpo["estado"] == "devuelto" and cuerpo["fecha_devolucion"] is not None
    assert cuerpo["multa"]["monto"] == 1500 and cuerpo["multa"]["dias_atraso"] == 3
    assert cuerpo["multa"]["estado"] == "pendiente"
    assert cuerpo["atrasado"] is False and cuerpo["dias_atraso"] == 3
    estado["multa_id"] = cuerpo["multa"]["id"]

    verificar(probadas, "E14", 401, client.post(f"/api/prestamos/{pid}/devolucion"))
    verificar(probadas, "E14", 403, client.post(f"/api/prestamos/{pid}/devolucion",
                                                headers=con_token(estado["t_ana"])))
    verificar(probadas, "E14", 404, client.post("/api/prestamos/9999/devolucion", headers=tb))
    verificar(probadas, "E14", 409, client.post(f"/api/prestamos/{pid}/devolucion", headers=tb),
              "PRESTAMO_YA_DEVUELTO")

    # Devolución a tiempo: sin multa, y la copia vuelve a estar disponible
    a_tiempo = client.post(f"/api/prestamos/{estado['p_pedro'][0]}/devolucion",
                           headers=tb).get_json()
    assert a_tiempo["multa"] is None
    detalle = client.get(f"/api/libros/{estado['libro_id']}", headers=tb).get_json()
    assert detalle["copias_disponibles"] == 3


# ---------------------------------------------------------------------------
# E13 · Listado del bibliotecario
# ---------------------------------------------------------------------------
def test_e13_listar_prestamos(client, estado, probadas):
    tb = con_token(estado["t_biblio"])
    cuerpo = verificar(probadas, "E13", 200, client.get("/api/prestamos?multa=pendiente",
                                                        headers=tb))
    assert cuerpo["total"] == 1 and cuerpo["items"][0]["multa"]["id"] == estado["multa_id"]
    cuerpo = client.get(f"/api/prestamos?socio_id={estado['pedro_id']}&estado=activo",
                        headers=tb).get_json()
    assert cuerpo["total"] == 2
    cuerpo = client.get("/api/prestamos", headers=tb).get_json()
    fechas = [(p["fecha_prestamo"], p["id"]) for p in cuerpo["items"]]
    assert fechas == sorted(fechas, reverse=True)              # más reciente primero
    verificar(probadas, "E13", 400, client.get("/api/prestamos?estado=perdido", headers=tb))
    verificar(probadas, "E13", 401, client.get("/api/prestamos"))
    verificar(probadas, "E13", 403, client.get("/api/prestamos",
                                               headers=con_token(estado["t_ana"])))


# ---------------------------------------------------------------------------
# E15 · Mis préstamos (la regla de pertenencia)
# ---------------------------------------------------------------------------
def test_e15_mis_prestamos(client, estado, probadas):
    ta, tp = con_token(estado["t_ana"]), con_token(estado["t_pedro"])
    cuerpo = verificar(probadas, "E15", 200, client.get("/api/mis-prestamos", headers=ta))
    assert cuerpo["total"] == 1
    assert all(p["socio"]["id"] == estado["ana_id"] for p in cuerpo["items"])
    assert cuerpo["items"][0]["multa"]["monto"] == 1500         # el socio ve su multa

    cuerpo = client.get("/api/mis-prestamos", headers=tp).get_json()
    assert cuerpo["total"] == 3
    assert all(p["socio"]["id"] == estado["pedro_id"] for p in cuerpo["items"])
    assert client.get("/api/mis-prestamos?estado=activo", headers=tp).get_json()["total"] == 2

    # Intento de colarse: ?socio_id se ignora y Ana sigue viendo SOLO lo suyo 🛡️
    cuerpo = client.get(f"/api/mis-prestamos?socio_id={estado['pedro_id']}", headers=ta).get_json()
    assert cuerpo["total"] == 1 and cuerpo["items"][0]["socio"]["id"] == estado["ana_id"]

    biblio = client.get("/api/mis-prestamos", headers=con_token(estado["t_biblio"])).get_json()
    assert biblio == {"total": 0, "items": []}

    verificar(probadas, "E15", 400, client.get("/api/mis-prestamos?estado=x", headers=ta))
    verificar(probadas, "E15", 401, client.get("/api/mis-prestamos"))


# ---------------------------------------------------------------------------
# E16 · Pago de multa
# ---------------------------------------------------------------------------
def test_e16_pago_multa(client, estado, probadas):
    tb, mid = con_token(estado["t_biblio"]), estado["multa_id"]
    cuerpo = verificar(probadas, "E16", 200, client.post(f"/api/multas/{mid}/pago", headers=tb))
    assert cuerpo["estado"] == "pagada" and cuerpo["fecha_pago"] is not None
    assert cuerpo["prestamo_id"] == estado["p_ana"] and cuerpo["monto"] == 1500
    verificar(probadas, "E16", 401, client.post(f"/api/multas/{mid}/pago"))
    verificar(probadas, "E16", 403, client.post(f"/api/multas/{mid}/pago",
                                                headers=con_token(estado["t_ana"])))
    verificar(probadas, "E16", 404, client.post("/api/multas/9999/pago", headers=tb))
    verificar(probadas, "E16", 409, client.post(f"/api/multas/{mid}/pago", headers=tb),
              "MULTA_YA_PAGADA")


# ---------------------------------------------------------------------------
# Extras: cuenta desactivada y rutas desconocidas
# ---------------------------------------------------------------------------
def test_cuenta_desactivada_pierde_el_token(app, client, estado):
    with app.app_context():
        u = db.session.get(Usuario, estado["pedro_id"])
        u.activo = False
        db.session.commit()
    r = client.get("/api/auth/yo", headers=con_token(estado["t_pedro"]))
    assert r.status_code == 401
    with app.app_context():
        db.session.get(Usuario, estado["pedro_id"]).activo = True
        db.session.commit()


def test_errores_genericos_con_formato_de_la_api(client):
    r = client.get("/api/no-existe")
    assert r.status_code == 404 and r.get_json()["codigo"] == 404
    r = client.patch("/api/libros")
    assert r.status_code == 405 and r.get_json()["codigo"] == 405


# ---------------------------------------------------------------------------
# La prueba final: ¿se probaron las 68 filas de 4-Salidas?
# ---------------------------------------------------------------------------
def test_cobertura_del_contrato(probadas):
    declaradas = {(e, c) for (e, c, _cuando) in SALIDAS}
    faltan = sorted(declaradas - probadas)
    sobran = sorted(probadas - declaradas)
    assert not faltan, f"Filas del contrato sin probar: {faltan}"
    assert not sobran, f"Respuestas probadas que NO están en el contrato: {sobran}"
