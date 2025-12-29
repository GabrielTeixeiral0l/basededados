-- =============================================================================
-- TESTE UNITÁRIO: TABELA ESTUDANTE (DDLv3)
-- Regras: Status, Idade Mínima (14), Telemóvel, NIF/CC/IBAN
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_est_id NUMBER;
    v_status_final VARCHAR2(1);
    v_count_erros NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA ESTUDANTE (DDLv3) ===');

    -- 1. Teste de Status Inválido
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "9")...');
    INSERT INTO estudante (nome, data_nascimento, nif, cc, telemovel, email, status)
    VALUES ('Estudante Teste Status', TO_DATE('2000-01-01', 'YYYY-MM-DD'), '111111111', '12345678', '912345678', 'est@teste.com', '9')
    RETURNING id, status INTO v_est_id, v_status_final;

    IF v_status_final = '0' THEN DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido.'); ELSE 
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status nao corrigido: '||v_status_final); v_count_erros := v_count_erros + 1; END IF;

    -- 2. Teste de Idade Inválida (Demasiado novo - 17 anos)
    DBMS_OUTPUT.PUT_LINE('2. Testando Idade Inválida (17 anos)...');
    BEGIN
        INSERT INTO estudante (nome, data_nascimento, nif, cc, telemovel, email, status)
        VALUES ('Menor de Idade', ADD_MONTHS(SYSDATE, -17*12), '222222222', '87654321', '911111111', 'jovem@teste.com', '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Idade inválida permitida.');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Idade inválida bloqueada.');
    END;

    -- 3. Teste de Telemóvel Inválido
    DBMS_OUTPUT.PUT_LINE('3. Testando Telemóvel Inválido (Letras)...');
    BEGIN
        INSERT INTO estudante (nome, data_nascimento, nif, cc, telemovel, email, status)
        VALUES ('Estudante Tel Mau', TO_DATE('1990-01-01', 'YYYY-MM-DD'), '111222333', '11223344', '91ABC4567', 'tel@teste.com', '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Telemovel invalido permitido.');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Telemovel invalido bloqueado.');
    END;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE ESTUDANTE: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE ESTUDANTE: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE ESTUDANTE !!! ' || SQLERRM);
    ROLLBACK;
END;
/
