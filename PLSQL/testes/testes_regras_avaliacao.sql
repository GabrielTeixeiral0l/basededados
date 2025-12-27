-- =============================================================================
-- TESTE DE REGRAS DE AVALIAÇÃO
-- Verifica: Grupos, Sub-avaliações e Entregas
-- =============================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_tipo_sem_grupo NUMBER;
    v_tipo_sem_filhos NUMBER;
    v_tipo_sem_entrega NUMBER;
    v_turma_id NUMBER;
    v_aval_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES DE REGRAS DE AVALIAÇÃO ===');

    -- 1. Obter ou Criar Tipos de Avaliação para Teste
    -- Tipo que NÃO permite grupo
    SELECT id INTO v_tipo_sem_grupo FROM tipo_avaliacao WHERE permite_grupo = '0' AND ROWNUM = 1;
    
    -- Tipo que NÃO permite filhos
    SELECT id INTO v_tipo_sem_filhos FROM tipo_avaliacao WHERE permite_filhos = '0' AND ROWNUM = 1;

    -- Tipo que NÃO requer entrega
    SELECT id INTO v_tipo_sem_entrega FROM tipo_avaliacao WHERE requer_entrega = '0' AND ROWNUM = 1;

    -- Obter uma turma qualquer
    SELECT id INTO v_turma_id FROM turma WHERE ROWNUM = 1;

    -- -------------------------------------------------------------------------
    -- TESTE 1: Tentar criar avaliação de grupo onde não é permitido
    -- Nota: A tabela AVALIACAO não tem coluna 'eh_grupo', a regra está no TIPO.
    -- Se a lógica é "Não posso associar grupos a esta avaliação", isso seria na tabela de grupos (que não existe no DDL).
    -- Assumindo que o teste original queria verificar outra coisa ou a regra mudou.
    -- Vou ignorar este teste se não houver coluna para validar grupo na tabela Avaliação.
    -- No DDLv3 não há indicação explícita de "é grupo" na tabela avaliacao.
    -- Vou remover este teste para evitar confusão ou assumir que é validado noutro lugar.
    DBMS_OUTPUT.PUT_LINE('--- Teste 1: Validacao de Grupo (Ignorado - Sem coluna de grupo na tabela Avaliacao) ---');

    -- -------------------------------------------------------------------------
    -- TESTE 2: Tentar criar sub-avaliação onde pai não permite
    DBMS_OUTPUT.PUT_LINE('--- Teste 2: Tentar criar sub-avaliação onde pai não permite ---');
    
    -- Criar Pai que não permite filhos
    INSERT INTO avaliacao (id, titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES (seq_avaliacao.NEXTVAL, 'Pai Sem Filhos', SYSDATE, SYSDATE, 100, 1, v_turma_id, v_tipo_sem_filhos)
    RETURNING id INTO v_aval_id;

    BEGIN
        INSERT INTO avaliacao (id, titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, avaliacao_pai_id)
        VALUES (seq_avaliacao.NEXTVAL, 'Filho Ilegal', SYSDATE, SYSDATE, 50, 1, v_turma_id, v_tipo_sem_filhos, v_aval_id);
        
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu criar filho ilegalmente.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Regra detetada: ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[ERRO] Excecao inesperada: ' || SQLERRM);
        END IF;
    END;

    -- -------------------------------------------------------------------------
    -- TESTE 3: Tentar entregar ficheiro onde não é requerido
    DBMS_OUTPUT.PUT_LINE('--- Teste 3: Tentar entregar ficheiro onde não é requerido ---');
    
    -- Criar Avaliação que não pede entrega
    INSERT INTO avaliacao (id, titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES (seq_avaliacao.NEXTVAL, 'Sem Entrega', SYSDATE, SYSDATE, 100, 1, v_turma_id, v_tipo_sem_entrega)
    RETURNING id INTO v_aval_id;

    BEGIN
        INSERT INTO entrega (id, data_entrega, avaliacao_id)
        VALUES (seq_entrega.NEXTVAL, SYSDATE, v_aval_id);
        
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu entrega ilegal.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20006 THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Regra detetada: ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[ERRO] Excecao inesperada: ' || SQLERRM);
        END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('=== TESTES DE REGRAS CONCLUÍDOS ===');
    ROLLBACK; -- Limpar dados de teste
END;
/