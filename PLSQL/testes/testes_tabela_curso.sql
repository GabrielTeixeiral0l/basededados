-- =============================================================================
-- TESTE UNITÁRIO: TABELA CURSO
-- Regras: Status (0/1), Duracao (>0), ECTS (>=0)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_curso_id NUMBER;
    v_status_final VARCHAR2(1);
    v_duracao_final NUMBER;
    v_ects_final NUMBER;
    v_tipo_id NUMBER;
    v_count_erros NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA CURSO ===');

    -- 1. Setup: Obter um tipo de curso existente
    SELECT id INTO v_tipo_id FROM (SELECT id FROM tipo_curso ORDER BY id) WHERE ROWNUM = 1;

    -- 2. Teste de Status Inválido
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "A")...');
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id, status)
    VALUES ('Curso Teste Status', 'CTS01', 'Descricao do curso teste', 3, 180, v_tipo_id, 'A')
    RETURNING id, status INTO v_curso_id, v_status_final;

    IF v_status_final = '0' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status manteve-se inválido: ' || v_status_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- 3. Teste de Duração Inválida
    DBMS_OUTPUT.PUT_LINE('2. Testando Duracao Inválida (Inserir 0)...');
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id, status)
    VALUES ('Curso Teste Duracao', 'CTD01', 'Descricao teste duracao', 0, 180, v_tipo_id, '1')
    RETURNING id, duracao INTO v_curso_id, v_duracao_final;

    IF v_duracao_final = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Duracao corrigida para 1.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Duracao manteve-se inválida: ' || v_duracao_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- 4. Teste de ECTS Inválidos
    DBMS_OUTPUT.PUT_LINE('3. Testando ECTS Inválidos (Inserir -10)...');
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id, status)
    VALUES ('Curso Teste ECTS', 'CTE01', 'Descricao teste ects', 3, -10, v_tipo_id, '1')
    RETURNING id, ects INTO v_curso_id, v_ects_final;

    IF v_ects_final = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] ECTS corrigidos para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] ECTS mantiveram-se inválidos: ' || v_ects_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE CURSO: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE CURSO: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE CURSO !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    ROLLBACK;
END;
/
