-- =============================================================================
-- 2. GATILHOS DE AUDITORIA E MANUTENÇÃO (COMPATÍVEL DDLV3)
-- Atualiza 'updated_at' e insere registos na tabela 'log' (texto simples).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Gatilho Genérico de Updated_At (Exemplo para tabela NOTA)
-- Deve ser replicado para outras tabelas se necessário.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_NOTA_UPDATED_AT
BEFORE UPDATE ON nota
FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSDATE;
END;
/

-- -----------------------------------------------------------------------------
-- Gatilho de Auditoria: NOTA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDIT_NOTA
AFTER INSERT OR UPDATE OR DELETE ON nota
FOR EACH ROW
DECLARE
    v_acao VARCHAR2(20);
    v_msg  VARCHAR2(4000);
BEGIN
    IF DELETING THEN
        v_acao := 'DELETE';
        v_msg := 'Nota apagada. ID Inscrição: ' || :OLD.inscricao_id;
    ELSIF INSERTING THEN
        v_acao := 'INSERT';
        v_msg := 'Nova nota: ' || :NEW.nota || ' (Inscrição: ' || :NEW.inscricao_id || ')';
    ELSE
        v_acao := 'UPDATE';
        v_msg := 'Nota alterada de ' || :OLD.nota || ' para ' || :NEW.nota;
    END IF;

    -- Verifica configuração global
    IF PKG_CONFIG_LOG.DEVE_REGISTAR('NOTA', v_acao) THEN
        INSERT INTO log (id, acao, tabela, data, created_at)
        VALUES (seq_log.NEXTVAL, v_acao, 'NOTA', v_msg, SYSDATE);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- Gatilho de Auditoria: ESTUDANTE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDIT_ESTUDANTE
AFTER INSERT OR UPDATE OR DELETE ON estudante
FOR EACH ROW
DECLARE
    v_acao VARCHAR2(20);
    v_msg  VARCHAR2(4000);
BEGIN
    IF DELETING THEN
        v_acao := 'DELETE';
        v_msg := 'Estudante apagado: ' || :OLD.nome;
    ELSIF INSERTING THEN
        v_acao := 'INSERT';
        v_msg := 'Novo estudante: ' || :NEW.nome;
    ELSE
        v_acao := 'UPDATE';
        v_msg := 'Estudante atualizado: ' || :NEW.nome;
    END IF;

    IF PKG_CONFIG_LOG.DEVE_REGISTAR('ESTUDANTE', v_acao) THEN
        INSERT INTO log (id, acao, tabela, data, created_at)
        VALUES (seq_log.NEXTVAL, v_acao, 'ESTUDANTE', v_msg, SYSDATE);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- Gatilho de Auditoria: MATRICULA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDIT_MATRICULA
AFTER INSERT OR UPDATE OR DELETE ON matricula
FOR EACH ROW
DECLARE
    v_acao VARCHAR2(20);
    v_msg  VARCHAR2(4000);
BEGIN
    IF DELETING THEN
        v_acao := 'DELETE';
        v_msg := 'Matrícula apagada: ' || :OLD.id;
    ELSIF INSERTING THEN
        v_acao := 'INSERT';
        v_msg := 'Nova matrícula: ' || :NEW.id;
    ELSE
        v_acao := 'UPDATE';
        v_msg := 'Matrícula atualizada. Estado ID: ' || :NEW.estado_matricula_id;
    END IF;

    IF PKG_CONFIG_LOG.DEVE_REGISTAR('MATRICULA', v_acao) THEN
        INSERT INTO log (id, acao, tabela, data, created_at)
        VALUES (seq_log.NEXTVAL, v_acao, 'MATRICULA', v_msg, SYSDATE);
    END IF;
END;
/