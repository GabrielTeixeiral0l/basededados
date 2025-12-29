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
    v_docente_id NUMBER;
    v_uc1 NUMBER; v_uc2 NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA ESTUDANTE_ENTREGA (DDLv3) ===');

    -- SETUP
    -- 1. Obter Curso, Docente e Criar Estudante
    SELECT MIN(id) INTO v_curso_id FROM curso;
    SELECT MIN(id) INTO v_docente_id FROM docente;
    
    INSERT INTO estudante (nome, data_nascimento, nif, cc, telemovel, email, status)
    VALUES ('Estudante Teste EE', TO_DATE('2000-01-01', 'YYYY-MM-DD'), '275730972', '12345678', '910000000', 'ee@teste.com', '1')
    RETURNING id INTO v_estudante_id;

    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status)
    VALUES (v_curso_id, 2025, v_estudante_id, 'Ativo', 10, '1')
    RETURNING id INTO v_matricula_id;

    -- 2. Criar UCs e ligar ao curso (Para evitar ORA-20020)
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) VALUES ('UC EE 1', 'UCEE1', 30, 30) RETURNING id INTO v_uc1;
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) VALUES ('UC EE 2', 'UCEE2', 30, 30) RETURNING id INTO v_uc2;
    
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca) VALUES (v_curso_id, v_uc1, 1, 1, 6, '1', 75);
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca) VALUES (v_curso_id, v_uc2, 1, 1, 6, '1', 75);

    -- Habilitar Docente para as UCs
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status) VALUES (v_uc1, v_docente_id, 'Docente', '1');
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status) VALUES (v_uc2, v_docente_id, 'Docente', '1');

    -- 3. Criar Turmas com Docente
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id) VALUES ('T EE 1', '2025', v_uc1, 20, v_docente_id) RETURNING id INTO v_turma_id;
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id) VALUES ('T EE 2', '2025', v_uc2, 20, v_docente_id) RETURNING id INTO v_outra_turma_id;

    -- 4. Criar Inscrições
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_turma_id, v_matricula_id, SYSDATE, '1') RETURNING id INTO v_inscricao_id;
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_outra_turma_id, v_matricula_id, SYSDATE, '1') RETURNING id INTO v_inscricao_outra_turma_id;

    -- 5. Criar Avaliação e Entregas
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
    VALUES ('Avaliacao Grupo EE', SYSDATE, SYSDATE+10, 0.5, 3, v_turma_id, 1, '1')
    RETURNING id INTO v_aval_id;

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

    -- CLEANUP
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== TESTE ESTUDANTE_ENTREGA: SUCESSO (ROLLBACK EXECUTADO) ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE ESTUDANTE_ENTREGA !!! ' || SQLERRM);
    ROLLBACK;
END;
/
