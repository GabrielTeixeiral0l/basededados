SET SERVEROUTPUT ON;
SET FEEDBACK OFF;

DECLARE
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    v_cur_id NUMBER; v_uc_id NUMBER; v_doc_id NUMBER; v_tur_id NUMBER;
    v_tc_id  NUMBER; v_est_id NUMBER; v_mat_id NUMBER;
    v_ins1 NUMBER; v_ins2 NUMBER; v_ins3 NUMBER;
    v_tipo_indiv_id NUMBER; v_tipo_grupo_id NUMBER;
    v_aval_id NUMBER; v_entrega_id NUMBER;
    v_max_alunos_check NUMBER;
    v_log_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE: REGRAS DE GRUPOS E LIMITES ===');

    -- 1. SETUP
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('T'||v_sufixo, 1000) RETURNING id INTO v_tc_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id)
    VALUES ('C'||v_sufixo, 'CT'||v_sufixo, 'D', 3, 180, 50, v_tc_id) RETURNING id INTO v_cur_id;
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
    VALUES ('U'||v_sufixo, 'UT'||v_sufixo, 20, 20) RETURNING id INTO v_uc_id;

    -- Ligar UC ao Curso
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca)
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', 75);

    INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel)
    VALUES ('P'||v_sufixo, SYSDATE, '267873072', '12345678', 'p@t.pt', '911111111') RETURNING id INTO v_doc_id;

    -- Habilitar Docente para a UC
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
    VALUES (v_uc_id, v_doc_id, 'Regente', '1');

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('T'||v_sufixo, '25/26', v_uc_id, 30, v_doc_id) RETURNING id INTO v_tur_id;

    -- Criar Inscrições
    -- Aluno 1
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('A1'||v_sufixo, '275730972', '11111111', SYSDATE-7000, '910000001', 'a1@t.pt') RETURNING id INTO v_est_id;
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat_id;
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins1; -- Corrigido v_ins1

    -- Aluno 2
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('A2'||v_sufixo, '257573097', '22222222', SYSDATE-7000, '910000002', 'a2@t.pt') RETURNING id INTO v_est_id;
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat_id;
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins2; -- Corrigido v_ins2

    -- Aluno 3
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('A3'||v_sufixo, '237300870', '33333333', SYSDATE-7000, '910000003', 'a3@t.pt') RETURNING id INTO v_est_id;
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat_id;
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins3; -- Corrigido v_ins3


    -- 2. CRIAR TIPOS DE AVALIAÇÃO (Ajustado para 'permite_grupo' conforme DDL)
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) 
    VALUES ('Individual '||v_sufixo, '0', '0', '0') RETURNING id INTO v_tipo_indiv_id;
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) 
    VALUES ('Grupo '||v_sufixo, '1', '1', '0') RETURNING id INTO v_tipo_grupo_id;

    -- -------------------------------------------------------------------------
    -- TESTE 1: FORÇAR LIMITE DE 1 ALUNO
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Cenario 1: Inserindo Avaliacao Individual com max_alunos = 10...');
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Exame', SYSDATE, SYSDATE, 10, 10, v_tur_id, v_tipo_indiv_id)
    RETURNING max_alunos INTO v_max_alunos_check;

    IF v_max_alunos_check = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[SUCESSO] O Trigger corrigiu max_alunos para 1.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] O valor continua: ' || v_max_alunos_check);
    END IF;

    -- -------------------------------------------------------------------------
    -- TESTE 2: LIMITE DE GRUPO NA ENTREGA
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Cenario 2: Testando limite de 2 alunos numa entrega...');
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Proj', SYSDATE, SYSDATE, 20, 2, v_tur_id, v_tipo_grupo_id) RETURNING id INTO v_aval_id;
    INSERT INTO entrega (data_entrega, avaliacao_id) VALUES (SYSDATE, v_aval_id) RETURNING id INTO v_entrega_id;

    INSERT INTO estudante_entrega (entrega_id, inscricao_id) VALUES (v_entrega_id, v_ins1);
    INSERT INTO estudante_entrega (entrega_id, inscricao_id) VALUES (v_entrega_id, v_ins2);
    
    BEGIN
        INSERT INTO estudante_entrega (entrega_id, inscricao_id) VALUES (v_entrega_id, v_ins3);
        DBMS_OUTPUT.PUT_LINE('[FALHA] Terceiro aluno permitido num grupo de 2.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Terceiro aluno bloqueado pelo trigger.');
    END;

    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ERRO' AND data LIKE '%'||v_entrega_id||'%';

    IF v_log_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[SUCESSO] O sistema registrou o erro no LOG.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Log de erro não encontrado.');
    END IF;

    ROLLBACK; 
    DBMS_OUTPUT.PUT_LINE('=== FIM DOS TESTES DE GRUPOS ===');
END;
/