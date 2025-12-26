-- =============================================================================
-- 2. GATILHOS DE MANUTENÇÃO (UPDATED_AT) E AUDITORIA
-- Corrigido: Coluna "DATA" entre aspas no trigger de audit
-- =============================================================================

CREATE OR REPLACE TRIGGER TRG_AULA_UPDATED_AT 
    BEFORE UPDATE ON aula FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_AVALIACAO_UPDATED_AT 
    BEFORE UPDATE ON avaliacao FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_CURSO_UPDATED_AT 
    BEFORE UPDATE ON curso FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_DOCENTE_UPDATED_AT 
    BEFORE UPDATE ON docente FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_ENTREGA_UPDATED_AT 
    BEFORE UPDATE ON entrega FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_ESTUDANTE_UPDATED_AT 
    BEFORE UPDATE ON estudante FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_EST_ENTREGA_UPDATED_AT 
    BEFORE UPDATE ON estudante_entrega FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_FICH_ENTREGA_UPDATED_AT 
    BEFORE UPDATE ON ficheiro_entrega FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_FICH_RECURSO_UPDATED_AT 
    BEFORE UPDATE ON ficheiro_recurso FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_INSCRICAO_UPDATED_AT 
    BEFORE UPDATE ON inscricao FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_MATRICULA_UPDATED_AT 
    BEFORE UPDATE ON matricula FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_NOTA_UPDATED_AT 
    BEFORE UPDATE ON nota FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_PARCELA_UPDATED_AT 
    BEFORE UPDATE ON parcela_propina FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_PRESENCA_UPDATED_AT 
    BEFORE UPDATE ON presenca FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_RECURSO_UPDATED_AT 
    BEFORE UPDATE ON recurso FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_SALA_UPDATED_AT 
    BEFORE UPDATE ON sala FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_T_AULA_UPDATED_AT 
    BEFORE UPDATE ON tipo_aula FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_T_AVAL_UPDATED_AT 
    BEFORE UPDATE ON tipo_avaliacao FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_T_CURSO_UPDATED_AT 
    BEFORE UPDATE ON tipo_curso FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_TURMA_UPDATED_AT 
    BEFORE UPDATE ON turma FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_UC_CURSO_UPDATED_AT 
    BEFORE UPDATE ON uc_curso FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_UC_DOC_UPDATED_AT 
    BEFORE UPDATE ON uc_docente FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

CREATE OR REPLACE TRIGGER TRG_UC_UPDATED_AT 
    BEFORE UPDATE ON unidade_curricular FOR EACH ROW 
BEGIN 
    :NEW.updated_at := SYSDATE; 
END;
/

-- -----------------------------------------------------------------------------
-- Auditoria Forense para NOTA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDIT_NOTA
    AFTER INSERT OR UPDATE OR DELETE ON nota
    FOR EACH ROW
DECLARE 
    v_acao VARCHAR2(20); 
    v_msg VARCHAR2(4000);
BEGIN
    IF DELETING THEN 
        v_acao := 'DELETE'; 
        v_msg := 'Nota apagada. Inscrição: ' || :OLD.inscricao_id;
    ELSIF INSERTING THEN 
        v_acao := 'INSERT'; 
        v_msg := 'Nova nota: ' || :NEW.nota;
    ELSE 
        v_acao := 'UPDATE'; 
        v_msg := 'Nota alterada: ' || :OLD.nota || ' -> ' || :NEW.nota;
    END IF;

    IF PKG_CONFIG_LOG.DEVE_REGISTAR('NOTA', v_acao) THEN
        INSERT INTO log (id, acao, tabela, "DATA", created_at) 
        VALUES (seq_log.NEXTVAL, v_acao, 'NOTA', v_msg, SYSDATE);
    END IF;
END;
/
