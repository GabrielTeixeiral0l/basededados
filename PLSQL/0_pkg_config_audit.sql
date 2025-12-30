--LOGS ()
CREATE OR REPLACE PACKAGE PKG_LOG AS
    PROCEDURE REGISTAR(p_acao VARCHAR2, p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL);
    PROCEDURE REGISTAR_DML(p_tabela VARCHAR2, p_acao VARCHAR2, p_id_registo VARCHAR2);
    PROCEDURE ERRO(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL);
    PROCEDURE ALERTA(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL);
END PKG_LOG;
/

CREATE OR REPLACE PACKAGE BODY PKG_LOG AS
    PROCEDURE REGISTAR(p_acao VARCHAR2, p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL) IS
        -- O PRAGMA AUTONOMOUS_TRANSACTION Garante que o registo no LOG seja persistido (COMMIT) mesmo que a transação principal (que chamou este log) sofra um ROLLBACK devido a um erro. Essencial para auditoria e depuração.
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- Regista se a auditoria estiver ativa OU se for um erro crítico
        IF PKG_CONSTANTES.AUDIT_ENABLED OR p_acao = 'ERRO' THEN
            INSERT INTO log (acao, tabela, data, created_at)
            VALUES (p_acao, p_tabela, p_msg, CURRENT_TIMESTAMP);
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; 
    END;

    PROCEDURE REGISTAR_DML(p_tabela VARCHAR2, p_acao VARCHAR2, p_id_registo VARCHAR2) IS
    BEGIN
        REGISTAR(p_acao, 'Registo ID: ' || p_id_registo, p_tabela);
    END;

    PROCEDURE ERRO(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL) IS
    BEGIN
        REGISTAR('ERRO', p_msg, p_tabela);
    END;

    PROCEDURE ALERTA(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL) IS
    BEGIN
        REGISTAR('ALERTA', p_msg, p_tabela);
    END;
END PKG_LOG;
/