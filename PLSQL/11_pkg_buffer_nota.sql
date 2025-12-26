-- =============================================================================
-- 11. PACOTE DE BUFFER PARA CÁLCULO DE NOTAS (SIMPLIFICADO)
-- Estrutura: Listas simples de números em vez de registos complexos
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_BUFFER_NOTA IS
    -- Listas simples de números (Arrays)
    TYPE t_lista_numeros IS TABLE OF NUMBER;

    -- Listas para guardar os pares (Inscrição, Avaliação Pai)
    v_ids_inscricao t_lista_numeros := t_lista_numeros();
    v_ids_pais      t_lista_numeros := t_lista_numeros();
    
    -- Lista para guardar inscrições que precisam de nota final
    v_ids_finais    t_lista_numeros := t_lista_numeros();

    -- Flag para evitar recursividade nos triggers
    g_a_calcular BOOLEAN := FALSE;

    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER);
    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER);
    PROCEDURE LIMPAR;
END PKG_BUFFER_NOTA;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUFFER_NOTA IS

    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER) IS
    BEGIN
        -- Adiciona ao final da lista (Simples e direto)
        v_ids_inscricao.EXTEND;
        v_ids_pais.EXTEND;
        
        v_ids_inscricao(v_ids_inscricao.LAST) := p_insc_id;
        v_ids_pais(v_ids_pais.LAST) := p_pai_id;
    END ADICIONAR_PAI;

    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER) IS
    BEGIN
        v_ids_finais.EXTEND;
        v_ids_finais(v_ids_finais.LAST) := p_insc_id;
    END ADICIONAR_FINAL;

    PROCEDURE LIMPAR IS
    BEGIN
        -- Esvazia as listas
        v_ids_inscricao.DELETE;
        v_ids_pais.DELETE;
        v_ids_finais.DELETE;
    END LIMPAR;

END PKG_BUFFER_NOTA;
/
