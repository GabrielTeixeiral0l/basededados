-- =============================================================================
-- 0. PACOTE DE CONFIGURAÇÃO DE AUDITORIA (SIMPLIFICADO)
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_CONFIG_LOG IS
    FUNCTION DEVE_REGISTAR(
        p_tabela IN VARCHAR2, 
        p_acao   IN VARCHAR2
    ) RETURN BOOLEAN;
END PKG_CONFIG_LOG;
/

CREATE OR REPLACE PACKAGE BODY PKG_CONFIG_LOG IS
    
    C_GLOBAL_LOG_ATIVO BOOLEAN := TRUE; 

    FUNCTION DEVE_REGISTAR(
        p_tabela IN VARCHAR2, 
        p_acao   IN VARCHAR2
    ) RETURN BOOLEAN 
    IS
        v_tab VARCHAR2(50) := UPPER(p_tabela);
        v_act VARCHAR2(10) := UPPER(p_acao);
    BEGIN
        -- Retorna o valor padrão global se não houver exceção definida
        RETURN C_GLOBAL_LOG_ATIVO;
    END DEVE_REGISTAR;

END PKG_CONFIG_LOG;
/