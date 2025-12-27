-- =============================================================================
-- 0. PACOTE CENTRAL DE LOGS E AUDITORIA (PKG_LOG)
-- Centraliza todas as operações de registo de eventos.
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_LOG IS
    -- Configuração: Ativa/Desativa logs globalmente
    G_ATIVO BOOLEAN := TRUE;

    -- Procedimento para registar DML (Aceita ID como VARCHAR2 para chaves compostas)
    PROCEDURE REGISTAR_DML(p_tabela IN VARCHAR2, p_acao IN VARCHAR2, p_id_registo IN VARCHAR2, p_detalhes IN VARCHAR2 DEFAULT NULL);
    
    -- Procedimentos para Alertas e Erros
    PROCEDURE ALERTA(p_msg IN VARCHAR2);
    PROCEDURE ERRO(p_contexto IN VARCHAR2, p_erro_msg IN VARCHAR2 DEFAULT NULL);
    
    -- Função para verificar se deve registar
    FUNCTION DEVE_REGISTAR(p_tabela IN VARCHAR2) RETURN BOOLEAN;
END PKG_LOG;
/

CREATE OR REPLACE PACKAGE BODY PKG_LOG IS

    FUNCTION DEVE_REGISTAR(p_tabela IN VARCHAR2) RETURN BOOLEAN IS
        v_tab VARCHAR2(50) := UPPER(p_tabela);
    BEGIN
        IF NOT G_ATIVO THEN RETURN FALSE; END IF;
        IF v_tab = 'LOG' THEN RETURN FALSE; END IF;
        RETURN TRUE;
    END DEVE_REGISTAR;

    PROCEDURE REGISTAR(p_acao IN VARCHAR2, p_tabela IN VARCHAR2, p_dados IN CLOB) IS
    BEGIN
        IF DEVE_REGISTAR(p_tabela) THEN
            INSERT INTO log (id, acao, tabela, "DATA", created_at)
            VALUES (seq_log.NEXTVAL, UPPER(p_acao), UPPER(p_tabela), p_dados, SYSDATE);
        END IF;
    EXCEPTION WHEN OTHERS THEN 
        NULL; -- Logs não devem quebrar a transação
    END REGISTAR;

    PROCEDURE REGISTAR_DML(p_tabela IN VARCHAR2, p_acao IN VARCHAR2, p_id_registo IN VARCHAR2, p_detalhes IN VARCHAR2 DEFAULT NULL) IS
        v_dados CLOB;
    BEGIN
        v_dados := 'PK: ' || p_id_registo;
        IF p_detalhes IS NOT NULL THEN
            v_dados := v_dados || ' | ' || p_detalhes;
        END IF;
        REGISTAR(p_acao, p_tabela, v_dados);
    END REGISTAR_DML;

    PROCEDURE ALERTA(p_msg IN VARCHAR2) IS
    BEGIN
        REGISTAR('ALERTA', 'SISTEMA', p_msg);
    END ALERTA;

    PROCEDURE ERRO(p_contexto IN VARCHAR2, p_erro_msg IN VARCHAR2 DEFAULT NULL) IS
        v_err CLOB := NVL(p_erro_msg, SUBSTR(SQLERRM, 1, 2000));
    BEGIN
        REGISTAR('ERRO', p_contexto, v_err);
    END ERRO;

END PKG_LOG;
/