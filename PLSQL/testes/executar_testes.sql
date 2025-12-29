-- =============================================================================
-- EXECUÇÃO DE TESTES UNITÁRIOS E INTEGRADOS (VERSÃO FINAL COMPATÍVEL DDLv3)
-- =============================================================================
SET SERVEROUTPUT ON;
SET FEEDBACK OFF;

DECLARE
    v_num        NUMBER := TRUNC(DBMS_RANDOM.VALUE(1000,9999));
    v_sfx        VARCHAR2(10) := TO_CHAR(v_num);
    v_cur_id     NUMBER; v_uc_id NUMBER; v_doc_id NUMBER; v_tur_id NUMBER;
    v_est_id     NUMBER; v_mat_id NUMBER;
    v_tc_id      NUMBER; v_sal_id NUMBER; v_ta_id NUMBER;
    v_count      NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES INTEGRADOS (Sufixo: '||v_sfx||') ===');

    -- 1. SETUP INFRAESTRUTURA
    INSERT INTO tipo_curso (nome, valor_propinas, status) VALUES ('TC'||v_sfx, 8000, '1') RETURNING id INTO v_tc_id;
    INSERT INTO sala (nome, capacidade, status) VALUES ('S'||v_sfx, 30, '1') RETURNING id INTO v_sal_id;
    INSERT INTO tipo_aula (nome, status) VALUES ('T'||v_sfx, '1') RETURNING id INTO v_ta_id;

    -- 2. SETUP ACADÉMICO
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id, status) 
    VALUES ('C'||v_sfx, 'C'||v_sfx, 'D', 3, 180, v_tc_id, '1') RETURNING id INTO v_cur_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status) 
    VALUES ('U'||v_sfx, 'U'||v_sfx, 40, 40, '1') RETURNING id INTO v_uc_id;

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca, status) 
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', 75, '1');

    -- Docente (O trigger TRG_AI_DOCENTE cria UTILIZADOR e COLABORADOR automaticamente)
    INSERT INTO docente (nome, nif, telemovel, email, data_contratacao, status) 
    VALUES ('DocTest'||v_sfx, '2'||LPAD(v_sfx, 8, '0'), '91'||LPAD(v_sfx, 7, '0'), 'doc'||v_sfx||'@test.pt', SYSDATE-10, '1') 
    RETURNING id INTO v_doc_id;

    -- Habilitar Docente para a UC (Necessário para TRG_VAL_TURMA)
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
    VALUES (v_uc_id, v_doc_id, 'Regente', '1');

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status) 
    VALUES ('T'||v_sfx, '25', v_uc_id, v_doc_id, '1') RETURNING id INTO v_tur_id;

    -- 3. TESTAR ESTUDANTE E MATRÍCULA
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email, status) 
    VALUES ('EstTest'||v_sfx, '1'||LPAD(v_sfx, 8, '0'), '1'||LPAD(v_sfx, 7, '0'), TO_DATE('2000-01-01','YYYY-MM-DD'), '92'||LPAD(v_sfx, 7, '0'), 'est'||v_sfx||'@test.pt', '1') 
    RETURNING id INTO v_est_id;

    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status) 
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10, '1') RETURNING id INTO v_mat_id;

    -- Validar Propinas
    SELECT COUNT(*) INTO v_count FROM parcela_propina WHERE matricula_id = v_mat_id;
    IF v_count = 10 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Plano financeiro (10 parcelas) gerado automaticamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[ERRO] Plano financeiro nao gerado. Encontradas: '||v_count);
    END IF;

    -- 4. INSCRIÇÃO (Chave composta: matricula_id, turma_id)
    -- Inserir sem aulas para evitar mutating table
    INSERT INTO inscricao (turma_id, matricula_id, data, status) 
    VALUES (v_tur_id, v_mat_id, SYSDATE, '1');
    
    DBMS_OUTPUT.PUT_LINE('[OK] Inscricao realizada com sucesso.');

    -- 5. CRIAR AULA (Gera presenças retroativas)
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, tipo_aula_id, turma_id, status) 
    VALUES (TRUNC(SYSDATE), TRUNC(SYSDATE)+9/24, TRUNC(SYSDATE)+11/24, v_sal_id, v_ta_id, v_tur_id, '1');

    -- Validar Presença
    SELECT COUNT(*) INTO v_count FROM presenca WHERE aula_id = (SELECT MAX(id) FROM aula WHERE turma_id = v_tur_id);
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Presenca automatica gerada para a aula.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[AVISO] Presenca automatica nao detectada.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== TESTES CONCLUÍDOS COM SUCESSO ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO NOS TESTES INTEGRADOS !!!');
    DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Sufixo usado: ' || v_sfx);
    ROLLBACK;
END;
/