-- =============================================================================
-- TESTE UNITÁRIO: TABELA PARCELA_PROPINA (Integridade e Regras de Negócio)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx         VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999)));
    v_tc_id       NUMBER;
    v_cur_id      NUMBER;
    v_est_id      NUMBER;
    v_mat_id      NUMBER;
    v_par_id      NUMBER;
    v_data_check  DATE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE: PARCELA_PROPINA ===');

    -- 1. SETUP DE DADOS
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('Financas '||v_sfx, 1000) RETURNING id INTO v_tc_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id) 
    VALUES ('Curso Fin '||v_sfx, 'CF'||v_sfx, 'Desc', 3, 180, 100, v_tc_id) RETURNING id INTO v_cur_id;
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel) 
    VALUES ('Aluno Fin '||v_sfx, '2'||v_sfx||'9999', '123456789ZZ1', SYSDATE-7000, 'af'||v_sfx||'@t.pt', '9'||v_sfx||'0000') 
    RETURNING id INTO v_est_id;
    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas) 
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10) RETURNING id INTO v_mat_id;

    DELETE FROM parcela_propina WHERE matricula_id = v_mat_id;
    DBMS_OUTPUT.PUT_LINE('[SETUP] Dados base criados. Matricula ID: ' || v_mat_id);

    -- 2. TESTE: VALOR NEGATIVO (INSERT)
    DBMS_OUTPUT.PUT_LINE('>> Teste 1: Valor Negativo (Bloqueio)...');
    BEGIN
        INSERT INTO parcela_propina (valor, data_vencimento, numero, matricula_id, estado)
        VALUES (-100, SYSDATE+30, 1, v_mat_id, '0');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu valor negativo!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou valor negativo.');
    END;

    -- 3. TESTE: DATA VENCIMENTO PASSADA (INSERT BLOQUEIA)
    DBMS_OUTPUT.PUT_LINE('>> Teste 2: Data Vencimento Passada no INSERT (Bloqueio)...');
    BEGIN
        INSERT INTO parcela_propina (valor, data_vencimento, numero, matricula_id, estado)
        VALUES (100, SYSDATE-1, 1, v_mat_id, '0');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu data passada no INSERT!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou data passada no INSERT.');
    END;

    -- 4. TESTE: DATA VENCIMENTO PASSADA NO UPDATE (PERMITE para multas)
    DBMS_OUTPUT.PUT_LINE('>> Teste 3: Data Vencimento Passada no UPDATE (Permite)...');
    INSERT INTO parcela_propina (valor, data_vencimento, numero, matricula_id, estado)
    VALUES (100, SYSDATE+30, 1, v_mat_id, '0') RETURNING id INTO v_par_id;
    
    BEGIN
        UPDATE parcela_propina SET data_vencimento = SYSDATE - 10 WHERE id = v_par_id;
        DBMS_OUTPUT.PUT_LINE('[OK] Permitiu data passada no UPDATE (necessario para testar multas).');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FALHA] Bloqueou data passada no UPDATE: ' || SQLERRM);
    END;

    -- 5. TESTE: DATA PAGAMENTO AUTOMÁTICA
    DBMS_OUTPUT.PUT_LINE('>> Teste 4: Data Pagamento Automatica ao Pagar...');
    UPDATE parcela_propina SET estado = '1' WHERE id = v_par_id;

    SELECT data_pagamento INTO v_data_check FROM parcela_propina WHERE id = v_par_id;
    
    IF v_data_check IS NOT NULL AND TRUNC(v_data_check) = TRUNC(SYSDATE) THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Data pagamento preenchida automaticamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Data pagamento nao preenchida.');
    END IF;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== TESTE PARCELA_PROPINA CONCLUIDO ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO FATAL NO TESTE: ' || SQLERRM);
    ROLLBACK;
END;
/