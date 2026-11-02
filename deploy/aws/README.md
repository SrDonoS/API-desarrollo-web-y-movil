# ☁️ Deploy en AWS — paso a paso

> Arquitectura: **📱 App Android → 🌐 Nginx → 🦄 Gunicorn + Flask (EC2) → 🐬 RDS MySQL**
> La cadena Nginx → Gunicorn → MySQL de esta carpeta se probó en un Ubuntu 24.04 (fuera de AWS): responde igual que en local. Lo propio de AWS (RDS, security groups, Elastic IP) se configura en la consola siguiendo estos pasos.

---

## 💸 0. Antes que nada: la billetera

1. **Billing → Budgets → Create budget** → plantilla *Zero spend* o *Monthly cost* con alerta (ej. USD 5) a tu correo.
2. Usa instancias chicas de la capa gratuita y **apágalas** cuando no estés probando.
3. ¿AWS Academy (Learner Lab)? La sesión expira y los recursos se pueden detener: por eso la **Elastic IP** (paso 3) es clave.

---

## 🐬 1. Base de datos: Amazon RDS (MySQL 8)

Consola → **RDS → Create database**:

| Opción | Valor |
|---|---|
| Engine | **MySQL 8.0** |
| Template | **Free tier** (o el más chico disponible) |
| DB instance identifier | `biblioteca-db` |
| Master username | `admin` (y una clave fuerte, guárdala) |
| Public access | **No** 🔒 |
| VPC security group | crea uno nuevo: `biblioteca-rds-sg` |
| Initial database name | `biblioteca` |

Cuando quede *Available*, copia el **Endpoint** (algo como `biblioteca-db.xxxx.us-east-1.rds.amazonaws.com`).

> 🔤 RDS crea la base con el juego de caracteres del *parameter group* por defecto. Para no pelear con tildes y ñ, crea la base explícitamente (paso 4) con `utf8mb4`.

---

## 🖥️ 2. Servidor: EC2 (Ubuntu 24.04)

Consola → **EC2 → Launch instance**:

| Opción | Valor |
|---|---|
| AMI | **Ubuntu Server 24.04 LTS** |
| Instance type | `t2.micro` / `t3.micro` (capa gratuita) |
| Key pair | crea uno y guarda el `.pem` (¡nunca a git!) |
| Security group | `biblioteca-ec2-sg` con: **22** solo *My IP*, **80** y **443** desde *Anywhere* |

Después, en el security group **de RDS** (`biblioteca-rds-sg`) agrega una regla de entrada: **MySQL/Aurora (3306)** con origen = el security group **del EC2** (`biblioteca-ec2-sg`). Así **solo** el EC2 puede hablar con la base. 🔐

---

## 📌 3. Elastic IP

**EC2 → Elastic IPs → Allocate → Associate** con tu instancia. Esa IP no cambia aunque reinicies, y es la que va en la app (o en el DNS de tu dominio).

---

## 🔧 4. Instalar la API en el EC2

```bash
ssh -i tu-llave.pem ubuntu@<ELASTIC-IP>

# Crear la base con utf8mb4 y un usuario propio para la app (no uses "admin" en la app)
sudo apt-get update -y && sudo apt-get install -y mysql-client
mysql -h <ENDPOINT-RDS> -u admin -p
```

```sql
CREATE DATABASE IF NOT EXISTS biblioteca CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'biblio_app'@'%' IDENTIFIED BY 'una-clave-fuerte-de-verdad';
GRANT ALL PRIVILEGES ON biblioteca.* TO 'biblio_app'@'%';
FLUSH PRIVILEGES;
```

```bash
git clone <URL-DE-TU-REPO> ~/biblioteca-comunitaria
cd ~/biblioteca-comunitaria
bash deploy/aws/instalar_en_ec2.sh       # la 1.ª vez crea el .env y se detiene
nano backend/.env                        # DATABASE_URL, JWT_SECRET_KEY nueva, FLASK_DEBUG=0
bash deploy/aws/instalar_en_ec2.sh       # ahora sí instala todo
```

`DATABASE_URL` en el servidor queda así:

```ini
DATABASE_URL=mysql+pymysql://biblio_app:una-clave-fuerte-de-verdad@<ENDPOINT-RDS>:3306/biblioteca?charset=utf8mb4
```

Crea el primer bibliotecario (en producción **no** se cargan los usuarios de prueba):

```bash
cd ~/biblioteca-comunitaria/backend
./venv/bin/flask --app run crear-bibliotecario
```

Prueba desde tu compu:

```bash
curl -i http://<ELASTIC-IP>/api/libros     # 401 = la API está viva y protegida ✅
```

Y Swagger en `http://<ELASTIC-IP>/docs` 📘.

---

## 🔒 5. HTTPS (necesita dominio)

1. Compra o usa un dominio y crea un registro **A**: `api.tudominio.cl → <ELASTIC-IP>`.
2. En `deploy/aws/nginx-biblioteca.conf` cambia `server_name _;` por `server_name api.tudominio.cl;` y vuelve a copiarlo.
3. Certificado gratis:
   ```bash
   sudo apt install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d api.tudominio.cl
   ```

Sin dominio se puede probar con `http://<ELASTIC-IP>`, pero Android exige `usesCleartextTraffic` para eso (solo pa' la demo).

---

## 📦 6. APK apuntando a AWS

```bash
cd app_movil
flutter build apk --release --dart-define=API_URL=https://api.tudominio.cl
# sin dominio (solo demo): --dart-define=API_URL=http://<ELASTIC-IP>
```

El APK queda en `app_movil/build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔄 Actualizar después de un cambio

```bash
cd ~/biblioteca-comunitaria
git pull
./backend/venv/bin/pip install -r backend/requirements.txt
cd backend && ./venv/bin/flask --app run db upgrade     # si hubo cambios en los modelos
sudo systemctl restart biblioteca-api
```

## 🩺 Si algo falla

| Síntoma | Revisa |
|---|---|
| `502 Bad Gateway` | Gunicorn está caído: `sudo journalctl -u biblioteca-api -n 50` |
| `Can't connect to MySQL server` | Security group de RDS (3306 desde el SG del EC2) y el endpoint en `DATABASE_URL` |
| `Falta configurar: DATABASE_URL` | El `.env` no está en `backend/` o tiene un error de tipeo |
| La app no conecta | ¿La URL del `--dart-define` es la Elastic IP / dominio? ¿Puerto 80/443 abiertos? |
| Vencimientos corridos 3 horas | `ZONA_HORARIA=America/Santiago` en el `.env` |
