-- =============================================================================
-- 0. PACOTE DE CONFIGURAÇÃO DE AUDITORIA (SIMPLIFICADO)
-- Controla se as ações devem ser registadas na tabela de LOG.
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_CONFIG_LOG IS
    -- Função chamada pelos triggers para saber se devem registar
    FUNCTION DEVE_REGISTAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2) RETURN BOOLEAN;
END PKG_CONFIG_LOG;
/

CREATE OR REPLACE PACKAGE BODY PKG_CONFIG_LOG IS
    
    -- =========================================================================
    -- CONFIGURAÇÃO GLOBAL
    -- TRUE = Regista tudo por defeito.
    -- FALSE = Não regista nada por defeito.
    -- =========================================================================
    C_GLOBAL_LOG_ATIVO CONSTANT BOOLEAN := TRUE; 

    -- =========================================================================

    FUNCTION DEVE_REGISTAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2) RETURN BOOLEAN IS
        v_tab VARCHAR2(50) := UPPER(p_tabela);
        v_act VARCHAR2(10) := UPPER(p_acao);
    BEGIN
        -- ---------------------------------------------------------------------
        -- EXCEÇÕES / OVERRIDES ESPECÍFICOS
        -- Aqui podes definir regras que contrariam o padrão global.
        -- Exemplo: Se o global for TRUE, podes desligar apenas DELETEs de NOTA.
        -- ---------------------------------------------------------------------
        
        -- Exemplo: Não registar SELECTs (se existissem) ou ações específicas
        -- IF v_tab = 'NOTA' AND v_act = 'DELETE' THEN RETURN FALSE; END IF;
        
        -- ---------------------------------------------------------------------
        
        -- Retorna o valor padrão global se não houver exceção
        RETURN C_GLOBAL_LOG_ATIVO;
    END DEVE_REGISTAR;

END PKG_CONFIG_LOG;
/
