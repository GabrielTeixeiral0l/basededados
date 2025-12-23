-- =============================================================================
-- 0. PACOTE DE CONFIGURAÇÃO DE AUDITORIA
-- Permite ligar/desligar logs por tabela e ação sem criar novas tabelas na BD.
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_CONFIG_LOG IS
    -- Ativa o log para uma tabela e ação específica
    PROCEDURE ATIVAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2);
    
    -- Desativa o log para uma tabela e ação específica
    PROCEDURE DESATIVAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2);
    
    -- Função chamada pelos triggers para saber se devem registar
    FUNCTION DEVE_REGISTAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2) RETURN BOOLEAN;
END PKG_CONFIG_LOG;
/

CREATE OR REPLACE PACKAGE BODY PKG_CONFIG_LOG IS
    -- Estrutura em memória para guardar as configurações (Chave -> Valor)
    -- Exemplo da Chave: 'NOTA:INSERT', Valor: TRUE/FALSE
    TYPE t_config_map IS TABLE OF BOOLEAN INDEX BY VARCHAR2(100);
    v_config t_config_map;

    -- Gera a chave única para o mapa
    FUNCTION GET_KEY(p_tabela IN VARCHAR2, p_acao IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN UPPER(p_tabela) || ':' || UPPER(p_acao);
    END;

    PROCEDURE ATIVAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2) IS
    BEGIN
        v_config(GET_KEY(p_tabela, p_acao)) := TRUE;
    END;

    PROCEDURE DESATIVAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2) IS
    BEGIN
        v_config(GET_KEY(p_tabela, p_acao)) := FALSE;
    END;

    FUNCTION DEVE_REGISTAR(p_tabela IN VARCHAR2, p_acao IN VARCHAR2) RETURN BOOLEAN IS
        v_key VARCHAR2(100);
    BEGIN
        v_key := GET_KEY(p_tabela, p_acao);
        
        -- Se a configuração existir, devolve o valor. Se não existir, assume TRUE (regista por defeito).
        IF v_config.EXISTS(v_key) THEN
            RETURN v_config(v_key);
        ELSE
            RETURN TRUE; -- Padrão: Tudo ligado
        END IF;
    END;

BEGIN
    -- CONFIGURAÇÃO INICIAL (Opcional: Desativar alguns por defeito aqui)
    -- Exemplo: v_config('ESTUDANTE:SELECT') := FALSE;
    NULL;
END PKG_CONFIG_LOG;
/
