"""
Punto de entrada de la API.

    Desarrollo:   python run.py
    Producción:   gunicorn -w 3 -b 127.0.0.1:8000 run:app

Luego abrir http://127.0.0.1:5000/docs  (Swagger, con el botón Authorize).
"""
import os

from app import crear_app

app = crear_app()

if __name__ == "__main__":
    # HOST=0.0.0.0 en el .env si quieres probar desde un celular en tu wifi.
    app.run(
        host=os.environ.get("HOST", "127.0.0.1"),
        port=int(os.environ.get("PORT", "5000")),
        debug=os.environ.get("FLASK_DEBUG", "1") == "1",
    )
