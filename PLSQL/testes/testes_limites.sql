-- =============================================================================
-- SCRIPT DE TESTES: LIMITES E RESTRIÇÕES (ECTS E CAPACIDADE) - COMPLETO
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sufixo VARCHAR2(10) := 'LIM_'||TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    v_est_id NUMBER; v_cur_id NUMBER; v_mat_id NUMBER;
    v_uc1_id NUMBER; v_uc2_id NUMBER;
    v_tur1_id NUMBER; v_tur2_id NUMBER;
    v_log_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES DE LIMITES ===');

    -- 1. SETUP (Curso e Estudante)
    SELECT MIN(id) INTO v_cur_id FROM curso;
    
    INSERT INTO estudante (nome, morada, data_nascimento, cc, nif, email, telemovel)
    VALUES ('Aluno Limite '||v_sufixo, 'Rua L', SYSDATE-7000, 
            SUBSTR('CC'||v_sufixo||'111',1,12), SUBSTR('9'||v_sufixo,1,9), 
            'l'||v_sufixo||'@test.com', '910000000') RETURNING id INTO v_est_id;

    INSERT INTO matricula (curso_id, estudante_id, estado_matricula_id, ano_inscricao, numero_parcelas)
    VALUES (v_cur_id, v_est_id, 1, 2025, 10) RETURNING id INTO v_mat_id;

    -- 2. TESTE DE CAPACIDADE DE TURMA (Limite: 1 aluno)
    DBMS_OUTPUT.PUT_LINE('1. Testando Limite de Capacidade da Turma...');
    
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('UC Limite', 'UCL'||v_sufixo, 40, 20) RETURNING id INTO v_uc1_id;

    -- Criar turma com capacidade MÁXIMA de 1 aluno
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('TURMA_CHEIA', '25/26', v_uc1_id, 1, (SELECT MIN(id) FROM docente)) RETURNING id INTO v_tur1_id;

    -- Inscrição 1 (OK)
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur1_id, v_mat_id, SYSDATE);

    -- Inscrição 2 (Deve gerar alerta de Turma Cheia)
    -- Vamos criar uma segunda matrícula fictícia para tentar entrar na mesma turma
    DECLARE
        v_mat2_id NUMBER;
        v_est2_id NUMBER;
    BEGIN
        INSERT INTO estudante (nome, cc, nif, email, telemovel, data_nascimento)
        VALUES ('Aluno Extra', SUBSTR('CC'||v_sufixo||'222',1,12), SUBSTR('8'||v_sufixo,1,9), 'x@x.com', '911111111', SYSDATE-7000)
        RETURNING id INTO v_est2_id;
        
        INSERT INTO matricula (curso_id, estudante_id, estado_matricula_id, ano_inscricao, numero_parcelas)
        VALUES (v_cur_id, v_est2_id, 1, 2025, 10) RETURNING id INTO v_mat2_id;
        
        INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur1_id, v_mat2_id, SYSDATE);
    END;

    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ALERTA' AND "DATA" LIKE '%atingiu o limite máximo%';

    IF v_log_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Sistema detectou turma cheia.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Sistema permitiu excesso de lotação sem alerta.');
    END IF;

    -- 3. TESTE DE LIMITE DE ECTS (Max 72)
    DBMS_OUTPUT.PUT_LINE('2. Testando Limite de ECTS...');
    
    -- Criar UC com 80 ECTS (excede o limite de 72 por defeito)
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('Super UC', 'SUC'||v_sufixo, 100, 100) RETURNING id INTO v_uc2_id;
    
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria)
    VALUES (v_cur_id, v_uc2_id, 1, 1, 80, '1');

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('TURMA_ECTS', '25/26', v_uc2_id, 30, (SELECT MIN(id) FROM docente)) RETURNING id INTO v_tur2_id;

    -- Tentar inscrever o aluno nesta UC gigante
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur2_id, v_mat_id, SYSDATE);

    -- Verificar se gerou alerta de ECTS
    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ALERTA' AND "DATA" LIKE '%Limite de ECTS anual excedido%';

    IF v_log_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Sistema detectou excesso de ECTS.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Sistema permitiu inscrição com ECTS excessivos sem alerta.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== TESTES DE LIMITES FINALIZADOS ===');

EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('!!! ERRO !!! ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
