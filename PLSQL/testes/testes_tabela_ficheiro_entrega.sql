-- =============================================================================
-- TESTE UNITÁRIO: TABELA FICHEIRO_ENTREGA
-- Regras: Status (0/1), Tamanho (0 < Tamanho <= 10MB)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_fich_id NUMBER;
    v_status_final VARCHAR2(1);
    v_entrega_id NUMBER;
    v_count_erros NUMBER := 0;
    v_tamanho_max NUMBER := PKG_CONSTANTES.TAMANHO_MAX_FICHEIRO;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA FICHEIRO_ENTREGA ===');

    -- 1. Setup: Obter uma entrega válida
    BEGIN
        SELECT id INTO v_entrega_id FROM (SELECT id FROM entrega ORDER BY id DESC) WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[ERRO] Nenhuma entrega encontrada. Execute os testes base primeiro.');
        RETURN;
    END;

    -- 2. Testando Status Inválido (Inserir "A")
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "A")...');
    INSERT INTO ficheiro_entrega (entrega_id, nome, ficheiro, tamanho, tipo, status)
    VALUES (v_entrega_id, 'teste_status.txt', EMPTY_BLOB(), 1024, 'text/plain', 'A')
    RETURNING id, status INTO v_fich_id, v_status_final;

    IF v_status_final = '0' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status manteve-se inválido: ' || v_status_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- 3. Testando Tamanho Zero (Deve bloquear)
    DBMS_OUTPUT.PUT_LINE('2. Testando Tamanho Zero (Limite Inferior)...');
    BEGIN
        INSERT INTO ficheiro_entrega (entrega_id, nome, ficheiro, tamanho, tipo)
        VALUES (v_entrega_id, 'vazio.txt', EMPTY_BLOB(), 0, 'text/plain');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Ficheiro com tamanho 0 foi permitido!');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Ficheiro com tamanho 0 bloqueado.');
    END;

    -- 4. Testando Tamanho Excessivo (Deve bloquear)
    DBMS_OUTPUT.PUT_LINE('3. Testando Tamanho Excessivo (' || (v_tamanho_max + 1) || ' bytes)...');
    BEGIN
        INSERT INTO ficheiro_entrega (entrega_id, nome, ficheiro, tamanho, tipo)
        VALUES (v_entrega_id, 'grande.zip', EMPTY_BLOB(), v_tamanho_max + 1, 'application/zip');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Ficheiro gigante foi permitido!');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Ficheiro gigante bloqueado.');
    END;

    -- 5. Testando Inserção Válida
    DBMS_OUTPUT.PUT_LINE('4. Testando Inserção Válida...');
    BEGIN
        INSERT INTO ficheiro_entrega (entrega_id, nome, ficheiro, tamanho, tipo, status)
        VALUES (v_entrega_id, 'trabalho.pdf', EMPTY_BLOB(), 5000, 'application/pdf', '1');
        DBMS_OUTPUT.PUT_LINE('[OK] Ficheiro válido inserido com sucesso.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FALHA] Ficheiro válido foi rejeitado: ' || SQLERRM);
        v_count_erros := v_count_erros + 1;
    END;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE FICHEIRO_ENTREGA: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE FICHEIRO_ENTREGA: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    ROLLBACK;
END;
/
