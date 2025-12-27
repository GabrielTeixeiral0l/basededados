-- =============================================================================
-- 4. PACOTE DE GESTÃO DE DADOS
-- Responsabilidade: Operações genéricas de dados (Soft Delete, Remoção)
-- Redireciona logs para o PKG_LOG.
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_GESTAO_DADOS IS
    -- Remove registo (Soft Delete se possível, Hard Delete caso contrário)
    -- NOTA: Apenas para tabelas com PK simples numérica chamada 'ID'
    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id_registo IN NUMBER);
    
    -- Wrappers para compatibilidade
    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2);
    PROCEDURE PRC_LOG_ERRO(p_contexto IN VARCHAR2);
END PKG_GESTAO_DADOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_DADOS IS

    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2) IS
    BEGIN
        PKG_LOG.ALERTA(p_msg);
    END PRC_LOG_ALERTA;

    PROCEDURE PRC_LOG_ERRO(p_contexto IN VARCHAR2) IS
    BEGIN
        PKG_LOG.ERRO(p_contexto);
    END PRC_LOG_ERRO;

    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id_registo IN NUMBER) IS
        v_sql VARCHAR2(500);
        v_tab VARCHAR2(30) := UPPER(p_nome_tabela);
    BEGIN
        -- Tenta soft delete se a tabela tiver STATUS
        BEGIN
            v_sql := 'UPDATE ' || v_tab || ' SET status = ''0'', updated_at = SYSDATE WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id_registo;
            
            -- Se não atualizou nada, tenta hard delete
            IF SQL%ROWCOUNT = 0 THEN
                v_sql := 'DELETE FROM ' || v_tab || ' WHERE id = :1';
                EXECUTE IMMEDIATE v_sql USING p_id_registo;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Fallback imediato para delete se o update falhar (ex: coluna status não existe)
            v_sql := 'DELETE FROM ' || v_tab || ' WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id_registo;
        END;
        
        -- O log da operação é feito automaticamente pelos triggers de auditoria (TRG_AUDIT_...)
    EXCEPTION WHEN OTHERS THEN 
        PKG_LOG.ERRO('REMOVER_' || v_tab);
    END PRC_REMOVER;

END PKG_GESTAO_DADOS;
/
