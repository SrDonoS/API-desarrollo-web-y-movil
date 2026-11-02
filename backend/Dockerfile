# =====================================================================
#  Imagen de la API (Flask + Gunicorn).
#
#  Construir (dentro de backend/):
#    docker build -t biblioteca-api .
#
#  Correr (las variables van en un archivo aparte, NUNCA dentro de la imagen):
#    docker run -d --name biblioteca-api --restart unless-stopped \
#      -p 80:8000 --env-file ~/api.env biblioteca-api
#
#  Guía completa para 2 EC2 (API + base de datos): deploy/docker/README.md
# =====================================================================
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Primero las dependencias: si solo cambias código, Docker reutiliza esta capa
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# No correr como root dentro del contenedor
RUN useradd --create-home --uid 1000 api
USER api

EXPOSE 8000

# 1) Aplica las migraciones (crea o actualiza las tablas en MySQL).
# 2) Arranca Gunicorn escuchando en 0.0.0.0 (si escucha en 127.0.0.1, no se puede entrar desde fuera del contenedor).
CMD ["sh", "-c", "flask --app run db upgrade && exec gunicorn --workers 3 --bind 0.0.0.0:8000 --access-logfile - run:app"]
