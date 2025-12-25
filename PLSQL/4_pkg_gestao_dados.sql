-- =============================================================================
-- 4. PACOTE DE GESTÃO DE DADOS (INTELLIGENT DELETE)
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_GESTAO_DADOS IS
    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2);
    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id_registo IN NUMBER, p_forcar_hard IN BOOLEAN DEFAULT FALSE);
END PKG_GESTAO_DADOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_DADOS IS

    C_GLOBAL_SOFT_DELETE CONSTANT BOOLEAN := TRUE;

    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('>> ALERTA: ' || p_msg);
        INSERT INTO log (id, acao, tabela, data, created_at)
        VALUES (seq_log.NEXTVAL, 'ALERTA', 'SISTEMA', p_msg, SYSDATE);
        COMMIT;
    EXCEPTION WHEN OTHERS THEN ROLLBACK;
    END PRC_LOG_ALERTA;

    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id_registo IN NUMBER, p_forcar_hard IN BOOLEAN DEFAULT FALSE) IS
        v_sql VARCHAR2(500);
        v_has_status NUMBER;
    BEGIN
        -- Verifica se a tabela tem coluna 'status' para decidir entre Soft e Hard Delete
        SELECT COUNT(*) INTO v_has_status FROM user_tab_columns 
        WHERE table_name = UPPER(p_nome_tabela) AND column_name = 'STATUS';

        IF v_has_status > 0 AND C_GLOBAL_SOFT_DELETE AND NOT p_forcar_hard THEN
            v_sql := 'UPDATE ' || p_nome_tabela || ' SET status = ''0'', updated_at = SYSDATE WHERE id = :1';
        ELSE
            v_sql := 'DELETE FROM ' || p_nome_tabela || ' WHERE id = :1';
        END IF;

        EXECUTE IMMEDIATE v_sql USING p_id_registo;
        
        IF SQL%ROWCOUNT = 0 THEN
            PRC_LOG_ALERTA('ID ' || p_id_registo || ' não encontrado em ' || p_nome_tabela);
        END IF;
        COMMIT;
    END PRC_REMOVER;

END PKG_GESTAO_DADOS;
/
