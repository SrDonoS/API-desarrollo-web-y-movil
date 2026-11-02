-- Lo ejecuta docker-compose la primera vez: crea la base de pruebas.
CREATE DATABASE IF NOT EXISTS biblioteca_test
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON biblioteca_test.* TO 'biblio_app'@'%';
FLUSH PRIVILEGES;
