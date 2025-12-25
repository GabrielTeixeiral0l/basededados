-- =============================================================================
-- 4. PACOTE DE GESTÃO DE DADOS (CORRIGIDO PARA DDLV3)
-- Adaptado para a estrutura da tabela LOG sem chaves estrangeiras.
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_GESTAO_DADOS IS
    -- Procedimento para registar alertas
    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2);

    -- Procedimento para remover registos
    PROCEDURE PRC_REMOVER(
        p_nome_tabela      IN VARCHAR2,
        p_id_registo       IN NUMBER,
        p_forcar_hard      IN BOOLEAN DEFAULT FALSE
    );
END PKG_GESTAO_DADOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_DADOS IS

    C_GLOBAL_SOFT_DELETE CONSTANT BOOLEAN := TRUE;

    -- =========================================================================
    -- PROCEDIMENTO DE LOG DE ALERTA (Adaptado ao DDLV3)
    -- Tabela LOG: id, acao, tabela, data, created_at
    -- =========================================================================
    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- 1. Output na consola
        DBMS_OUTPUT.PUT_LINE('>> ALERTA: ' || p_msg);

        -- 2. Inserir na tabela LOG (Estrutura Simplificada)
        -- Assume-se que seq_log existe.
        INSERT INTO log (
            id, 
            acao, 
            tabela, 
            data, 
            created_at
        ) VALUES (
            seq_log.NEXTVAL,
            'ALERTA',   -- Texto fixo em vez de ID
            'SISTEMA',  -- Origem do log
            p_msg,      -- Mensagem no CLOB
            SYSDATE
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('FALHA AO GRAVAR LOG NA BD: ' || SQLERRM);
            ROLLBACK;
    END PRC_LOG_ALERTA;

    -- =========================================================================
    -- PROCEDIMENTO DE REMOÇÃO
    -- =========================================================================
    PROCEDURE PRC_REMOVER(
        p_nome_tabela      IN VARCHAR2,
        p_id_registo       IN NUMBER,
        p_forcar_hard      IN BOOLEAN DEFAULT FALSE
    ) IS
        v_sql VARCHAR2(500);
        e_nao_encontrado EXCEPTION;
    BEGIN
        IF C_GLOBAL_SOFT_DELETE AND NOT p_forcar_hard THEN
            -- Verifica se a tabela tem colunas de status (assumido que sim no DDLv3 para as principais)
            v_sql := 'UPDATE ' || p_nome_tabela || ' SET status = ''0'', updated_at = SYSDATE WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id_registo;
        ELSE
            v_sql := 'DELETE FROM ' || p_nome_tabela || ' WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id_registo;
        END IF;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE e_nao_encontrado;
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN e_nao_encontrado THEN
            PRC_LOG_ALERTA('Remover: ID ' || p_id_registo || ' na tabela ' || p_nome_tabela || ' não existe.');
        WHEN OTHERS THEN
            ROLLBACK;
            PRC_LOG_ALERTA('Erro remover (' || p_nome_tabela || '): ' || SQLERRM);
    END PRC_REMOVER;

END PKG_GESTAO_DADOS;
/