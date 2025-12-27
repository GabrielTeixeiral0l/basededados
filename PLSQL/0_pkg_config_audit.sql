-- =============================================================================
-- 0. CONFIGURAÇÃO DE AUDITORIA E LOGS (TOTALMENTE COMPATÍVEL COM DDL V3)
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_LOG AS
    v_modo_manutencao BOOLEAN := FALSE;

    PROCEDURE REGISTAR(p_acao VARCHAR2, p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL);
    PROCEDURE REGISTAR_DML(p_tabela VARCHAR2, p_acao VARCHAR2, p_id_registo VARCHAR2);
    PROCEDURE ERRO(p_msg VARCHAR2);
    PROCEDURE ALERTA(p_msg VARCHAR2);
END PKG_LOG;
/

CREATE OR REPLACE PACKAGE BODY PKG_LOG AS
    PROCEDURE REGISTAR(p_acao VARCHAR2, p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- Ajustado para as colunas reais do DDL V3: id, acao, tabela, data, created_at
        INSERT INTO log (acao, tabela, data, created_at)
        VALUES (p_acao, p_tabela, p_msg, CURRENT_TIMESTAMP);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; 
    END;

    PROCEDURE REGISTAR_DML(p_tabela VARCHAR2, p_acao VARCHAR2, p_id_registo VARCHAR2) IS
    BEGIN
        REGISTAR(p_acao, 'Registo ID: ' || p_id_registo, p_tabela);
    END;

    PROCEDURE ERRO(p_msg VARCHAR2) IS
    BEGIN
        REGISTAR('ERRO', p_msg);
    END;

    PROCEDURE ALERTA(p_msg VARCHAR2) IS
    BEGIN
        REGISTAR('ALERTA', p_msg);
    END;
END PKG_LOG;
/