-- =============================================================================
-- 11. PACOTE DE BUFFER PARA CÁLCULO DE NOTAS (EVITAR TABELA MUTANTE)
-- Corrigido: Adicionada flag g_a_calcular para evitar recursividade infinita
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_BUFFER_NOTA IS
    TYPE t_rec IS RECORD (inscricao_id NUMBER, pai_id NUMBER);
    TYPE t_tab IS TABLE OF t_rec;
    
    v_lista t_tab := t_tab();
    
    TYPE t_insc_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    v_lista_insc t_insc_tab;

    -- Flag para evitar recursividade nos triggers
    g_a_calcular BOOLEAN := FALSE;

    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER);
    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER);
    PROCEDURE LIMPAR;
END PKG_BUFFER_NOTA;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUFFER_NOTA IS

    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER) IS
        v_idx NUMBER;
    BEGIN
        -- Evita duplicados simples (opcional, mas bom para performance)
        FOR i IN 1..v_lista.COUNT LOOP
            IF v_lista(i).inscricao_id = p_insc_id AND v_lista(i).pai_id = p_pai_id THEN
                RETURN;
            END IF;
        END LOOP;

        v_lista.EXTEND;
        v_idx := v_lista.LAST;
        v_lista(v_idx).inscricao_id := p_insc_id;
        v_lista(v_idx).pai_id := p_pai_id;
    END ADICIONAR_PAI;

    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER) IS
    BEGIN
        v_lista_insc(p_insc_id) := 1;
    END ADICIONAR_FINAL;

    PROCEDURE LIMPAR IS
    BEGIN
        v_lista.DELETE;
        v_lista_insc.DELETE;
    END LIMPAR;

END PKG_BUFFER_NOTA;
/