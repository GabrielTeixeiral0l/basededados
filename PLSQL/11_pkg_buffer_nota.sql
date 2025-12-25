-- =============================================================================
-- 11. PACOTE DE BUFFER PARA CÁLCULO DE NOTAS
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_BUFFER_NOTA IS
    -- Lista para processar notas hierárquicas (Filho -> Pai)
    TYPE t_rec IS RECORD (inscricao_id NUMBER, pai_id NUMBER);
    TYPE t_tab IS TABLE OF t_rec INDEX BY BINARY_INTEGER;
    v_lista t_tab;

    -- Lista para processar a nota final da UC (Inscrição)
    TYPE t_insc IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    v_lista_insc t_insc;

    PROCEDURE LIMPAR;
    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER);
    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER);
END PKG_BUFFER_NOTA;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUFFER_NOTA IS
    PROCEDURE LIMPAR IS 
    BEGIN 
        v_lista.DELETE; 
        v_lista_insc.DELETE;
    END;
    
    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER) IS
    BEGIN
        v_lista(v_lista.COUNT + 1).inscricao_id := p_insc_id;
        v_lista(v_lista.COUNT + 1).pai_id := p_pai_id;
    END;

    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER) IS
    BEGIN
        v_lista_insc(p_insc_id) := p_insc_id; -- Usa o ID como chave para evitar duplicados
    END;
END PKG_BUFFER_NOTA;
/