-- =============================================================================
-- 13. PACKAGE BUFFER MATRICULA
-- Gere estado para evitar Tabela Mutante no cálculo de médias
-- =============================================================================
CREATE OR REPLACE PACKAGE PKG_BUFFER_MATRICULA IS
    TYPE t_lista_ids IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    v_ids_matricula t_lista_ids;
    
    PROCEDURE LIMPAR;
    PROCEDURE ADICIONAR(p_id NUMBER);
END PKG_BUFFER_MATRICULA;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUFFER_MATRICULA IS
    PROCEDURE LIMPAR IS
    BEGIN
        v_ids_matricula.DELETE;
    END;

    PROCEDURE ADICIONAR(p_id NUMBER) IS
        v_idx NUMBER;
    BEGIN
        -- Evitar duplicados simples (opcional, mas bom para performance)
        v_idx := v_ids_matricula.COUNT + 1;
        v_ids_matricula(v_idx) := p_id;
    END;
END PKG_BUFFER_MATRICULA;
/