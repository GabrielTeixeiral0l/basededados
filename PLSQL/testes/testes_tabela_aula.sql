-- =============================================================================
-- TESTE UNITÁRIO: TABELA AULA
-- Regras: Status (0/1), Sequência Temporal (Fim > Início)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_aula_id NUMBER;
    v_status_final VARCHAR2(1);
    v_fim_final DATE;
    v_count_erros NUMBER := 0;
    
    v_sala_id NUMBER;
    v_turma_id NUMBER;
    v_tipo_id NUMBER;
    v_inicio DATE := TRUNC(SYSDATE) + INTERVAL '10' HOUR; -- Hoje às 10:00
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA AULA ===');

    -- 1. Setup de Dependências
    SELECT id INTO v_sala_id FROM (SELECT id FROM sala ORDER BY id) WHERE ROWNUM = 1;
    SELECT id INTO v_turma_id FROM (SELECT id FROM turma ORDER BY id) WHERE ROWNUM = 1;
    SELECT id INTO v_tipo_id FROM (SELECT id FROM tipo_aula ORDER BY id) WHERE ROWNUM = 1;

    -- 1. Teste de Status Inválido
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "9")...');
    -- Usar data futura para evitar conflitos de horário com dados existentes
    INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id, status)
    VALUES (SYSDATE+1000, TO_DATE('10:00','HH24:MI'), TO_DATE('12:00','HH24:MI'), 'Aula Teste Status', 1, 1, 1, '9')
    RETURNING id, status INTO v_aula_id, v_status_final;

    IF v_status_final = '0' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status manteve-se inválido: ' || v_status_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- 3. Teste de Hora Fim Inválida (Fim < Início)
    DBMS_OUTPUT.PUT_LINE('2. Testando Hora Fim Inválida (Fim < Início)...');
    -- Início às 10:00, Fim às 09:00
    -- Usar data muito futura para evitar conflitos
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, turma_id, tipo_aula_id, status)
    VALUES (TRUNC(SYSDATE)+2000, v_inicio, v_inicio - INTERVAL '1' HOUR, v_sala_id, v_turma_id, v_tipo_id, '1')
    RETURNING id, hora_fim INTO v_aula_id, v_fim_final;

    IF v_fim_final > v_inicio THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Hora de fim ajustada para ser posterior ao início: ' || TO_CHAR(v_fim_final, 'HH24:MI'));
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Hora de fim continua inválida: ' || TO_CHAR(v_fim_final, 'HH24:MI'));
        v_count_erros := v_count_erros + 1;
    END IF;

    -- 4. Teste de Conflito de Sala
    DBMS_OUTPUT.PUT_LINE('3. Testando Conflito de Sala (Sobreposição)...');
    -- Criar primeira aula
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, turma_id, tipo_aula_id, status)
    VALUES (TRUNC(SYSDATE)+5, v_inicio, v_inicio + INTERVAL '2' HOUR, v_sala_id, v_turma_id, v_tipo_id, '1');
    
    BEGIN
        -- Tentar criar segunda aula na mesma sala e hora
        INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, turma_id, tipo_aula_id, status)
        VALUES (TRUNC(SYSDATE)+5, v_inicio + INTERVAL '1' HOUR, v_inicio + INTERVAL '3' HOUR, v_sala_id, v_turma_id, v_tipo_id, '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Conflito de sala permitido.');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Conflito de sala bloqueado pelo sistema.');
    END;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE AULA: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE AULA: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE AULA !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    ROLLBACK;
END;
/
