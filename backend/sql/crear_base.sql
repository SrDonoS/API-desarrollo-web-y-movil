-- =====================================================================
--  Crea la base, la base de pruebas y el usuario de la app.
--  Correr UNA vez como root (MySQL Workbench o: mysql -u root -p < sql/crear_base.sql)
--  Las TABLAS no se crean aquí: las crean las migraciones (flask db upgrade).
-- =====================================================================
CREATE DATABASE IF NOT EXISTS biblioteca
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

CREATE DATABASE IF NOT EXISTS biblioteca_test
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

CREATE USER IF NOT EXISTS 'biblio_app'@'localhost' IDENTIFIED BY 'cambia-esta-clave';
GRANT ALL PRIVILEGES ON biblioteca.*      TO 'biblio_app'@'localhost';
GRANT ALL PRIVILEGES ON biblioteca_test.* TO 'biblio_app'@'localhost';
FLUSH PRIVILEGES;

-- ¿Usas XAMPP (MariaDB)? Cambia utf8mb4_0900_ai_ci por utf8mb4_unicode_ci.
