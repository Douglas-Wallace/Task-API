-- Evolui o banco da Tarefa 02 para a Tarefa 03 (usuarios + dono das tarefas)
USE taskdb;

CREATE TABLE usuarios (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(120) NOT NULL,
    email      VARCHAR(160) NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    CONSTRAINT uk_usuarios_email UNIQUE (email)
);

-- Senhas de teste: ana123 e bruno123 (PBKDF2-SHA256)
INSERT INTO usuarios (nome, email, senha_hash) VALUES
('Ana Souza',   'ana@taskapi.test',   'pbkdf2$120000$aeXcEUO4dAEjdH1fDeV5ag==$USvvNiYB5KBXSTJsDt9TU2z0olmsfZEB0Pi4zjf3k4Y='),
('Bruno Lima',  'bruno@taskapi.test', 'pbkdf2$120000$umrpUNrzKTtPNI/0tLKMiQ==$wWgcALwz3ERc/omcQ84qpuDZtdi82VWS5vjEIvakX4s=');

ALTER TABLE tarefas ADD COLUMN usuario_id INT NULL;

-- Tarefas antigas passam a pertencer a Ana
UPDATE tarefas
   SET usuario_id = (SELECT id FROM usuarios WHERE email = 'ana@taskapi.test')
 WHERE usuario_id IS NULL;

ALTER TABLE tarefas
    MODIFY concluida BOOLEAN NOT NULL DEFAULT FALSE,
    MODIFY usuario_id INT NOT NULL,
    ADD CONSTRAINT fk_tarefas_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id);

INSERT INTO tarefas (titulo, descricao, concluida, usuario_id)
SELECT 'Ler sobre Service Layer', 'Capitulo do Fowler', FALSE, id
  FROM usuarios WHERE email = 'ana@taskapi.test';

INSERT INTO tarefas (titulo, descricao, concluida, usuario_id)
SELECT t.titulo, t.descricao, t.concluida, u.id
  FROM usuarios u
  JOIN (SELECT 'Comprar cafe' AS titulo, 'Para a semana' AS descricao, TRUE AS concluida
        UNION ALL SELECT 'Revisar sessoes HTTP', 'Cookies e JSESSIONID', FALSE
        UNION ALL SELECT 'Entregar relatorio', 'Tarefa 03', FALSE) t
 WHERE u.email = 'bruno@taskapi.test';
