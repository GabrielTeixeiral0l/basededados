-- =============================================================================
-- TESTES UNITÁRIO: TABELA PRESENÇA (CORRIGIDO PARA DDLv3)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx       VARCHAR2(10) := TRIM(TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999))));
    v_doc_id    NUMBER; v_tc_id NUMBER; v_cur_id NUMBER; v_est_id NUMBER; v_mat_id NUMBER;
    v_uc_id     NUMBER; v_tur_a NUMBER; v_tur_b NUMBER;
    v_sala_a    NUMBER; v_sala_b NUMBER;
    v_ta_id     NUMBER;
    v_insc_a    NUMBER; v_aula_a_hoje NUMBER; v_aula_a_futura NUMBER; v_aula_b NUMBER;
    v_check     CHAR(1);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE: PRESENÇA ===');

    -- 1. SETUP ISOLADO
    -- Criar tipo de aula para garantir que existe
    INSERT INTO tipo_aula (nome, status) VALUES ('T_PRES_'||v_sfx, '1') RETURNING id INTO v_ta_id;

    INSERT INTO docente (nome, nif, cc, data_contratacao, email, telemovel, iban, status)
    VALUES ('DocP '||v_sfx, '2'||v_sfx||'0000', '1'||v_sfx||'000', SYSDATE-30, 'dp'||v_sfx||'@t.pt', '96'||v_sfx||'000', 'PT50000000000000000000000', '1')
    RETURNING id INTO v_doc_id;

    INSERT INTO sala (nome, capacidade, status) VALUES ('SA'||v_sfx, 30, '1') RETURNING id INTO v_sala_a;
    INSERT INTO sala (nome, capacidade, status) VALUES ('SB'||v_sfx, 30, '1') RETURNING id INTO v_sala_b;

    INSERT INTO tipo_curso (nome, valor_propinas, status) VALUES ('TP'||v_sfx, 1000, '1') RETURNING id INTO v_tc_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id, status) 
    VALUES ('CP'||v_sfx, 'CP'||v_sfx, 'D', 3, 180, v_tc_id, '1') RETURNING id INTO v_cur_id;
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status) 
    VALUES ('UP'||v_sfx, 'UP'||v_sfx, 10, 10, '1') RETURNING id INTO v_uc_id;
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, status) 
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', '1');

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status) VALUES ('TA'||v_sfx, '25', v_uc_id, v_doc_id, '1') RETURNING id INTO v_tur_a;
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status) VALUES ('TB'||v_sfx, '25', v_uc_id, v_doc_id, '1') RETURNING id INTO v_tur_b;

    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel, iban, status) 
    VALUES ('EstP'||v_sfx, '2'||v_sfx||'1111', '1'||v_sfx||'111', TO_DATE('2000-01-01','YYYY-MM-DD'), 'ep'||v_sfx||'@t.pt', '912345678', 'PT50000000000000000000000', '1') 
    RETURNING id INTO v_est_id;
    
    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status) 
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10, '1') RETURNING id INTO v_mat_id;
    
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_tur_a, v_mat_id, SYSDATE, '1') RETURNING id INTO v_insc_a;

    -- Aulas (Inscricao deve ser visivel para TRG_AUTO_PRESENCA_AULA)
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, tipo_aula_id, turma_id, status) 
    VALUES (TRUNC(SYSDATE), TRUNC(SYSDATE)+8/24, TRUNC(SYSDATE)+10/24, v_sala_a, v_ta_id, v_tur_a, '1') RETURNING id INTO v_aula_a_hoje;
    
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, tipo_aula_id, turma_id, status) 
    VALUES (TRUNC(SYSDATE+1), TRUNC(SYSDATE+1)+8/24, TRUNC(SYSDATE+1)+10/24, v_sala_a, v_ta_id, v_tur_a, '1') RETURNING id INTO v_aula_a_futura;
    
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, tipo_aula_id, turma_id, status) 
    VALUES (TRUNC(SYSDATE), TRUNC(SYSDATE)+11/24, TRUNC(SYSDATE)+13/24, v_sala_b, v_ta_id, v_tur_b, '1') RETURNING id INTO v_aula_b;

    -- TESTE 1: PRESENÇA EM AULA FUTURA
    DBMS_OUTPUT.PUT_LINE('>> Teste 1: Marcar presenca em aula futura (Deve forçar falta)...');
    
    -- Garantir que o registo de presença existe (criado pelo trigger)
    DECLARE 
        v_dummy CHAR(1); 
    BEGIN
        SELECT presente INTO v_dummy FROM presenca WHERE inscricao_id = v_insc_a AND aula_id = v_aula_a_futura;
        
        UPDATE presenca SET presente = '1' WHERE inscricao_id = v_insc_a AND aula_id = v_aula_a_futura;
        
        SELECT presente INTO v_check FROM presenca WHERE inscricao_id = v_insc_a AND aula_id = v_aula_a_futura;
        IF v_check = '0' THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Sistema impediu presenca futura.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] Sistema permitiu presenca futura!');
        END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[FALHA] Trigger TRG_AUTO_PRESENCA_AULA nao criou o registo.');
    END;

    -- TESTE 2: TURMA ERRADA
    DBMS_OUTPUT.PUT_LINE('>> Teste 2: Registar presenca em turma errada (Deve bloquear)...');
    BEGIN
        INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_insc_a, v_aula_b, '1', '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitido presenca em turma errada!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou presenca em turma errada.');
    END;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== TESTE PRESENÇA CONCLUIDO ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO FATAL NO TESTE PRESENCA !!!');
    DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
    ROLLBACK;
END;
/
