-- =============================================================================
-- TESTE UNITÁRIO: TABELA ESTUDANTE_ENTREGA (DDLv3)
-- Regras: Consistência Turma-Inscrição, Duplicação de Grupo
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_inscricao_id NUMBER;
    v_inscricao_outra_turma_id NUMBER;
    v_turma_id NUMBER;
    v_outra_turma_id NUMBER;
    v_aval_id NUMBER;
    v_entrega1_id NUMBER;
    v_entrega2_id NUMBER;
    v_estudante_id NUMBER;
    v_curso_id NUMBER;
    v_matricula_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA ESTUDANTE_ENTREGA (DDLv3) ===');

    -- SETUP
    -- 1. Obter Curso e Criar Estudante
    SELECT id INTO v_curso_id FROM curso WHERE ROWNUM = 1;
    
    INSERT INTO estudante (nome, data_nascimento, nif, cc, telemovel, email, status)
    VALUES ('Estudante Teste EE', TO_DATE('2000-01-01', 'YYYY-MM-DD'), '275730972', '12345678', '910000000', 'ee@teste.com', '1')
    RETURNING id INTO v_estudante_id;

    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status)
    VALUES (v_curso_id, 2025, v_estudante_id, 'Ativo', 10, '1')
    RETURNING id INTO v_matricula_id;

    -- 2. Obter duas turmas diferentes
    SELECT id INTO v_turma_id FROM turma WHERE ROWNUM = 1;
    SELECT id INTO v_outra_turma_id FROM turma WHERE id != v_turma_id AND ROWNUM = 1;

    -- 3. Criar Inscrições
    INSERT INTO inscricao (turma_id, matricula_id, data, status)
    VALUES (v_turma_id, v_matricula_id, SYSDATE, '1')
    RETURNING id INTO v_inscricao_id;

    INSERT INTO inscricao (turma_id, matricula_id, data, status)
    VALUES (v_outra_turma_id, v_matricula_id, SYSDATE, '1')
    RETURNING id INTO v_inscricao_outra_turma_id;

    -- 4. Criar Avaliação na Turma 1
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
    VALUES ('Avaliacao Grupo EE', SYSDATE, SYSDATE+10, 0.5, 3, v_turma_id, 1, '1')
    RETURNING id INTO v_aval_id;

    -- 5. Criar duas entregas para essa avaliação
    INSERT INTO entrega (data_entrega, avaliacao_id, status) VALUES (SYSDATE, v_aval_id, '1') RETURNING id INTO v_entrega1_id;
    INSERT INTO entrega (data_entrega, avaliacao_id, status) VALUES (SYSDATE, v_aval_id, '1') RETURNING id INTO v_entrega2_id;


    -- TESTE 1: Inscrição de outra turma (Consistência)
    DBMS_OUTPUT.PUT_LINE('1. Testando Inscrição de Outra Turma...');
    BEGIN
        INSERT INTO estudante_entrega (inscricao_id, entrega_id, status)
        VALUES (v_inscricao_outra_turma_id, v_entrega1_id, '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Inconsistencia de turma permitida.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Inconsistencia bloqueada.');
    END;

    -- TESTE 2: Duplicação (Mesma inscrição em dois grupos da mesma avaliação)
    DBMS_OUTPUT.PUT_LINE('2. Testando Duplicação de Grupo...');
    -- Inserir no Grupo A (Sucesso)
    INSERT INTO estudante_entrega (inscricao_id, entrega_id, status)
    VALUES (v_inscricao_id, v_entrega1_id, '1');
    
    -- Tentar inserir no Grupo B (Falha)
    BEGIN
        INSERT INTO estudante_entrega (inscricao_id, entrega_id, status)
        VALUES (v_inscricao_id, v_entrega2_id, '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Duplicacao de grupo permitida.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Duplicacao bloqueada.');
    END;

    -- CLEANUP
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== TESTE ESTUDANTE_ENTREGA: SUCESSO (ROLLBACK EXECUTADO) ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE ESTUDANTE_ENTREGA !!! ' || SQLERRM);
    ROLLBACK;
END;
/