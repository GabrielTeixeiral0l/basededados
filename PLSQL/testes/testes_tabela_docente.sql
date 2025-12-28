-- =============================================================================
-- TESTE UNITÁRIO: TABELA DOCENTE (DDLv3)
-- Regras: Status, Data Contratação <= SYSDATE, NIF/CC (Numericos), Telemovel
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_docente_id NUMBER;
    v_status_final VARCHAR2(1);
    v_dt_cont_final DATE;
    v_count_erros NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA DOCENTE (DDLv3) ===');

    -- 1. Teste de Status Inválido (Com dados válidos)
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "X")...');
    INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel, status)
    VALUES ('Docente Teste', SYSDATE, '123456789', '12345678', 'docente@teste.com', '912345678', 'X')
    RETURNING id, status INTO v_docente_id, v_status_final;

    IF v_status_final = '0' THEN 
        DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido.'); 
    ELSE 
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status nao corrigido: '||v_status_final); 
        v_count_erros := v_count_erros + 1; 
    END IF;
    
    -- 1.1 Teste Data Futura
    DBMS_OUTPUT.PUT_LINE('1.1. Testando Data Contratacao Futura...');
    BEGIN
        INSERT INTO docente (nome, data_contratacao, nif, email, telemovel)
        VALUES ('Docente Futuro', SYSDATE+365, '987654321', 'futuro@t.com', '911111111');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Data futura permitida.');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Data futura bloqueada.');
    END;

    -- 2. Teste NIF Inválido (Letras)
    DBMS_OUTPUT.PUT_LINE('2. Testando Insercao de NIF Inválido (Letras)...');
    BEGIN
        INSERT INTO docente (nome, data_contratacao, nif, email, telemovel, status)
        VALUES ('Docente NIF Mau', SYSDATE, 'ABC123456', 'mau@nif.com', '911111111', '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] NIF inválido permitido.');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] NIF invalido bloqueado.');
    END;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE DOCENTE: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE DOCENTE: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE DOCENTE !!! ' || SQLERRM);
    ROLLBACK;
END;
/