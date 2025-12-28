-- =============================================================================
-- TESTE UNITÁRIO: TABELA FICHEIRO_RECURSO
-- Regras: Status (0/1), Tamanho BLOB (0 < Tamanho <= 10MB)
-- =============================================================================
DECLARE
    v_fich_id NUMBER;
    v_status_final VARCHAR2(1);
    v_recurso_id NUMBER;
    v_count_erros NUMBER := 0;
    v_blob BLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA FICHEIRO_RECURSO ===');

    -- 1. Setup: Obter um recurso válido
    BEGIN
        SELECT id INTO v_recurso_id FROM (SELECT id FROM recurso ORDER BY id DESC) WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[ERRO] Nenhum recurso encontrado. Execute os testes base primeiro.');
        RETURN;
    END;

    -- 2. Testando Status Inválido (Inserir "X")
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "X")...');
    INSERT INTO ficheiro_recurso (recurso_id, nome, ficheiro, status)
    VALUES (v_recurso_id, 'teste_status.txt', UTL_RAW.CAST_TO_RAW('Conteudo de teste'), 'X')
    RETURNING id, status INTO v_fich_id, v_status_final;

    IF v_status_final = '0' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status manteve-se inválido: ' || v_status_final);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- 3. Testando Ficheiro Vazio (Deve bloquear)
    DBMS_OUTPUT.PUT_LINE('2. Testando Ficheiro Vazio (NULL/Empty)...');
    BEGIN
        INSERT INTO ficheiro_recurso (recurso_id, nome, ficheiro)
        VALUES (v_recurso_id, 'vazio.txt', EMPTY_BLOB());
        DBMS_OUTPUT.PUT_LINE('[FALHA] Ficheiro vazio foi permitido!');
        v_count_erros := v_count_erros + 1;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Ficheiro vazio bloqueado pelo trigger.');
    END;

    -- 4. Testando Inserção Válida
    DBMS_OUTPUT.PUT_LINE('3. Testando Inserção Válida...');
    BEGIN
        INSERT INTO ficheiro_recurso (recurso_id, nome, ficheiro, status)
        VALUES (v_recurso_id, 'aula_docente.pdf', UTL_RAW.CAST_TO_RAW('PDF SIMULADO'), '1');
        DBMS_OUTPUT.PUT_LINE('[OK] Ficheiro de recurso inserido com sucesso.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FALHA] Ficheiro válido foi rejeitado: ' || SQLERRM);
        v_count_erros := v_count_erros + 1;
    END;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE FICHEIRO_RECURSO: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE FICHEIRO_RECURSO: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE FICHEIRO_RECURSO !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    ROLLBACK;
END;
/
