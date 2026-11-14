CREATE DATABASE IF NOT EXISTS taskdb;
USE taskdb;

CREATE TABLE IF NOT EXISTS usuarios (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(120) NOT NULL,
    email      VARCHAR(160) NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    CONSTRAINT uk_usuarios_email UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS tarefas (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    titulo     VARCHAR(120) NOT NULL,
    descricao  VARCHAR(500),
    concluida  BOOLEAN NOT NULL DEFAULT FALSE,
    usuario_id INT NOT NULL,
    CONSTRAINT fk_tarefas_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
);

-- Senhas de teste: ana123 e bruno123 (PBKDF2-SHA256)
INSERT INTO usuarios (id, nome, email, senha_hash) VALUES
(1, 'Ana Souza',  'ana@taskapi.test',   'pbkdf2$120000$aeXcEUO4dAEjdH1fDeV5ag==$USvvNiYB5KBXSTJsDt9TU2z0olmsfZEB0Pi4zjf3k4Y='),
(2, 'Bruno Lima', 'bruno@taskapi.test', 'pbkdf2$120000$umrpUNrzKTtPNI/0tLKMiQ==$wWgcALwz3ERc/omcQ84qpuDZtdi82VWS5vjEIvakX4s=');

INSERT INTO tarefas (titulo, descricao, concluida, usuario_id) VALUES
('Estudar filtros',         'Ler o material da aula', FALSE, 1),
('Configurar o banco',      'MySQL + driver',         TRUE,  1),
('Ler sobre Service Layer', 'Capitulo do Fowler',     FALSE, 1),
('Comprar cafe',            'Para a semana',          TRUE,  2),
('Revisar sessoes HTTP',    'Cookies e JSESSIONID',   FALSE, 2),
('Entregar relatorio',      'Tarefa 03',              FALSE, 2);
