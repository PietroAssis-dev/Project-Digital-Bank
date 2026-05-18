-- Garante que está usando o banco certo
USE banco_digital;

-- ─── Usuários ─────────────────────────────────────────────────────────────────
CREATE TABLE users (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    username     VARCHAR(100)   NOT NULL,
    email        VARCHAR(255)   NOT NULL UNIQUE,
    cpf          VARCHAR(14)    NOT NULL UNIQUE,       -- formato: 000.000.000-00
    password     VARCHAR(60)    NOT NULL,              -- hash bcrypt = sempre 60 chars
    balance      DECIMAL(15,2)  NOT NULL DEFAULT 0.00,
    role         ENUM('user', 'admin') NOT NULL DEFAULT 'user',
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─── Chaves Pix ───────────────────────────────────────────────────────────────
CREATE TABLE pix_keys (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT            NOT NULL,
    key_type     ENUM('cpf', 'email', 'phone') NOT NULL DEFAULT 'cpf',
    key_value    VARCHAR(255)   NOT NULL UNIQUE,       -- o CPF/email/telefone em si
    is_active    TINYINT(1)     NOT NULL DEFAULT 1,
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ─── Transações ───────────────────────────────────────────────────────────────
CREATE TABLE transactions (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    sender_id    INT            NOT NULL,              -- quem enviou
    receiver_id  INT            NOT NULL,              -- quem recebeu
    amount       DECIMAL(15,2)  NOT NULL,
    type         ENUM('pix', 'deposit') NOT NULL,      -- pix = entre users, deposit = admin
    description  VARCHAR(255)   NULL,
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- ─── Logs de auditoria ────────────────────────────────────────────────────────
CREATE TABLE audit_logs (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    admin_id     INT            NOT NULL,              -- qual admin fez a ação
    target_id    INT            NOT NULL,              -- qual usuário foi afetado
    action       VARCHAR(100)   NOT NULL,              -- ex: 'DEPOSIT', 'BLOCK_USER'
    metadata     JSON           NULL,                  -- detalhes extras (valor, motivo...)
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (admin_id)  REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (target_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- ─── Índices de performance ───────────────────────────────────────────────────
CREATE INDEX idx_transactions_sender   ON transactions(sender_id);
CREATE INDEX idx_transactions_receiver ON transactions(receiver_id);
CREATE INDEX idx_pix_keys_user         ON pix_keys(user_id);
CREATE INDEX idx_audit_logs_admin      ON audit_logs(admin_id);

-- ─── Admin padrão (troque a senha depois!) ────────────────────────────────────
-- Senha: admin123 já hasheada com bcrypt rounds=10
INSERT INTO users (username, email, cpf, password, role) VALUES (
    'Admin',
    'admin@bancodigital.com',
    '000.000.000-00',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lMDi',
    'admin'
);