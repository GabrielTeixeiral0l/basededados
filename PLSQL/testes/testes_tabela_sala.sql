-- =============================================================================
-- TESTE UNITÁRIO: TABELA SALA (VERSÃO DDLV3)
-- Regras: Status (0/1), Capacidade (>0)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sala_id NUMBER;
    v_status_final VARCHAR2(1);
    v_cap_final NUMBER;
    v_count_erros NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA SALA (DDLv3) ===');

    -- 1. Teste de Status Inválido
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "X")...');
    
    INSERT INTO sala (nome, capacidade, status) 
    VALUES ('Sala Teste Status', 20, 'X')
    RETURNING id, status INTO v_sala_id, v_status_final;
    
    IF v_status_final = '0' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status manteve-se inválido: ' || v_status_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- 2. Teste de Capacidade Inválida
    DBMS_OUTPUT.PUT_LINE('2. Testando Capacidade Inválida (Inserir -5)...');
    
    INSERT INTO sala (nome, capacidade, status) 
    VALUES ('Sala Teste Cap', -5, '1')
    RETURNING id, capacidade INTO v_sala_id, v_cap_final;
    
    IF v_cap_final = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Capacidade corrigida para 1.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Capacidade manteve-se inválida: ' || v_cap_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE SALA: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE SALA: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE SALA !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    ROLLBACK;
END;
/