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
    v_prop_id     NUMBER;
    v_par_id      NUMBER;
    v_dummy       NUMBER;
    v_data_check  DATE;
    v_status_check CHAR(1);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE: PARCELA_PROPINA ===');

    -- 1. SETUP DE DADOS
    -- Criar Tipo Curso (1000€)
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('Financas '||v_sfx, 1000) RETURNING id INTO v_tc_id;
    
    -- Criar Curso
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id) 
    VALUES ('Curso Fin '||v_sfx, 'CF'||v_sfx, 'Desc', 3, 180, v_tc_id) RETURNING id INTO v_cur_id;

    -- Criar Estudante
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel) 
    VALUES ('Aluno Fin '||v_sfx, '2'||v_sfx||'9999', '1'||v_sfx||'888', SYSDATE-7000, 'af'||v_sfx||'@t.pt', '9'||v_sfx||'0000') 
    RETURNING id INTO v_est_id;

    -- Criar Matrícula (10 parcelas)
    -- O trigger TRG_AUTO_GERAR_PROPINAS vai criar a propina e parcelas automaticamente.
    -- Vamos apagar as parcelas geradas para testar inserção manual.
    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas) 
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10) RETURNING id INTO v_mat_id;

    SELECT id INTO v_prop_id FROM propina WHERE matricula_id = v_mat_id;
    DELETE FROM parcela_propina WHERE propina_id = v_prop_id; -- Limpar auto-geradas

    DBMS_OUTPUT.PUT_LINE('[SETUP] Dados base criados. Propina ID: ' || v_prop_id);

    -- 2. TESTE: VALOR NEGATIVO
    DBMS_OUTPUT.PUT_LINE('>> Teste 1: Valor Negativo...');
    BEGIN
        INSERT INTO parcela_propina (valor, data_vencimento, numero, propina_id, estado)
        VALUES (-100, SYSDATE+30, 1, v_prop_id, '0');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu valor negativo!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou valor negativo: ' || SQLERRM);
    END;

    -- 3. TESTE: DATA VENCIMENTO PASSADA
    DBMS_OUTPUT.PUT_LINE('>> Teste 2: Data Vencimento Passada...');
    BEGIN
        INSERT INTO parcela_propina (valor, data_vencimento, numero, propina_id, estado)
        VALUES (100, SYSDATE-1, 1, v_prop_id, '0');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu data passada!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou data passada: ' || SQLERRM);
    END;

    -- 4. TESTE: STATUS INVÁLIDO
    DBMS_OUTPUT.PUT_LINE('>> Teste 3: Status Invalido...');
    BEGIN
        INSERT INTO parcela_propina (valor, data_vencimento, numero, propina_id, estado)
        VALUES (100, SYSDATE+30, 1, v_prop_id, 'X') RETURNING id INTO v_par_id;
        
        -- Verificar se corrigiu
        SELECT estado INTO v_status_check FROM parcela_propina WHERE id = v_par_id;
        IF v_status_check = '0' THEN
             DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido para 0.');
        ELSE
             DBMS_OUTPUT.PUT_LINE('[FALHA] Status nao corrigido: ' || v_status_check);
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou status invalido (Exception).');
    END;

    -- 5. TESTE: DATA PAGAMENTO AUTOMÁTICA (Estado 1 -> Sysdate)
    DBMS_OUTPUT.PUT_LINE('>> Teste 4: Data Pagamento Automatica...');
    INSERT INTO parcela_propina (valor, data_vencimento, numero, propina_id, estado)
    VALUES (100, SYSDATE+30, 2, v_prop_id, '1') RETURNING id INTO v_par_id;

    SELECT data_pagamento INTO v_data_check FROM parcela_propina WHERE id = v_par_id;
    
    IF v_data_check IS NOT NULL AND TRUNC(v_data_check) = TRUNC(SYSDATE) THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Data pagamento preenchida automaticamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Data pagamento incorreta: ' || NVL(TO_CHAR(v_data_check), 'NULL'));
    END;

    -- 6. TESTE: CONSISTÊNCIA FINANCEIRA (Valor errado -> Log)
    DBMS_OUTPUT.PUT_LINE('>> Teste 5: Consistencia Financeira (Alerta)...');
    -- Total curso = 1000. Parcelas = 10. Valor correto = 100.
    -- Vamos inserir 50. Deve gerar alerta.
    INSERT INTO parcela_propina (valor, data_vencimento, numero, propina_id, estado)
    VALUES (50, SYSDATE+60, 3, v_prop_id, '0');
    
    -- Verificar Log
    BEGIN
        SELECT 1 INTO v_dummy FROM log 
        WHERE tabela = 'PARCELA_PROPINA' AND tipo = 'ALERTA' 
          AND mensagem LIKE '%Valor da parcela inconsistente%'
          AND created_at > SYSDATE - (1/1440); -- Ultimo minuto
        DBMS_OUTPUT.PUT_LINE('[OK] Alerta financeiro gerado no log.');
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[FALHA] Alerta financeiro NAO encontrado no log.');
    END;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== TESTE PARCELA_PROPINA CONCLUIDO ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO FATAL NO TESTE: ' || SQLERRM);
    ROLLBACK;
END;
/
