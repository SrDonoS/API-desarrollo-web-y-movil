#!/usr/bin/env bash
# =====================================================================
#  Instala la API en un EC2 con Ubuntu 24.04 recién creado.
#
#  Uso (conectado por SSH al EC2):
#    git clone <URL-DE-TU-REPO> ~/biblioteca-comunitaria
#    cd ~/biblioteca-comunitaria
#    bash deploy/aws/instalar_en_ec2.sh
#
#  Antes de correrlo: crea la base en RDS (ver deploy/aws/README.md).
#  El script se detiene si falta el .env, para que lo completes con el
#  endpoint de RDS y una JWT_SECRET_KEY nueva.
# =====================================================================
set -euo pipefail

REPO="$HOME/biblioteca-comunitaria"
BACKEND="$REPO/backend"

echo "📦 1/6 Paquetes del sistema..."
sudo apt-get update -y
sudo apt-get install -y python3-venv python3-pip nginx mysql-client git

echo "🕐 2/6 Hora de Chile en el servidor (los logs también)..."
sudo timedatectl set-timezone America/Santiago

echo "🐍 3/6 Entorno virtual y dependencias..."
cd "$BACKEND"
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

if [ ! -f "$BACKEND/.env" ]; then
  cp "$BACKEND/.env.example" "$BACKEND/.env"
  chmod 600 "$BACKEND/.env"
  echo ""
  echo "✋ Creé backend/.env desde la plantilla. Complétalo y vuelve a correr este script:"
  echo "   - DATABASE_URL  -> endpoint de RDS"
  echo "   - JWT_SECRET_KEY -> python3 -c \"import secrets; print(secrets.token_urlsafe(48))\""
  echo "   - FLASK_DEBUG=0"
  exit 1
fi

echo "🗃️  4/6 Tablas en RDS (migraciones)..."
./venv/bin/flask --app run init-db --sin-datos

echo "🦄 5/6 Servicio Gunicorn (systemd)..."
sudo cp "$REPO/deploy/aws/biblioteca-api.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now biblioteca-api
sudo systemctl restart biblioteca-api

echo "🌐 6/6 Nginx..."
sudo cp "$REPO/deploy/aws/nginx-biblioteca.conf" /etc/nginx/sites-available/biblioteca
sudo ln -sf /etc/nginx/sites-available/biblioteca /etc/nginx/sites-enabled/biblioteca
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo ""
echo "✅ Listo. Prueba:  curl -i http://<ELASTIC-IP>/api/libros   (debe responder 401 = la API está viva)"
echo "   Crea el primer bibliotecario:  cd $BACKEND && ./venv/bin/flask --app run crear-bibliotecario"
