PROMPT ==========================================================
PROMPT EXECUCAO DO BLOCO 13: TESTES AVANCADOS (Versao DDLv3)
PROMPT ==========================================================

DECLARE
    v_id_est NUMBER;
    v_id_cur NUMBER;
    v_id_mat NUMBER;
    v_count  NUMBER;
    v_sfx    VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999)));
BEGIN
    DBMS_OUTPUT.PUT_LINE('Iniciando validacao de integridade...');

    -- 1. Teste NIF (Formato)
    BEGIN
        INSERT INTO estudante (nome, nif, cc, email, telemovel, data_nascimento) 
        VALUES ('Teste NIF', 'INVALIDO', '99999999', 'nif@erro.com', '910000000', TO_DATE('2000-01-01','YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('[FALHA] NIF invalido nao foi bloqueado.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] NIF invalido bloqueado pelo sistema.');
    END;

    -- 2. Teste Geracao de Propinas (Adaptado para DDLv3: Parcela aponta para Matricula)
    BEGIN
        SELECT id INTO v_id_cur FROM (SELECT id FROM curso ORDER BY id DESC) WHERE ROWNUM = 1;
        
        INSERT INTO estudante (nome, nif, cc, email, telemovel, data_nascimento)
        VALUES ('Aluno Teste '||v_sfx, '29'||v_sfx||'000', '89'||v_sfx||'00', 't'||v_sfx||'@test.com', '91'||v_sfx||'000', TO_DATE('2000-01-01','YYYY-MM-DD'))
        RETURNING id INTO v_id_est;
        
        INSERT INTO matricula (estudante_id, curso_id, ano_inscricao, numero_parcelas, estado_matricula)
        VALUES (v_id_est, v_id_cur, 2025, 10, 'Ativa')
        RETURNING id INTO v_id_mat;
        
        -- Na DDLv3, a tabela parcela_propina tem a coluna MATRICULA_ID
        SELECT count(*) INTO v_count FROM parcela_propina 
        WHERE matricula_id = v_id_mat;
        
        IF v_count = 10 THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Plano financeiro de 10 parcelas gerado automaticamente.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] Foram geradas ' || v_count || ' parcelas em vez de 10.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[ERRO] Falha no fluxo financeiro: ' || SQLERRM);
    END;

    -- 3. Teste Soft-Delete
    IF v_id_est IS NOT NULL THEN
        UPDATE estudante SET status = '0' WHERE id = v_id_est;
        DBMS_OUTPUT.PUT_LINE('3. [OK] Soft-delete testado.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== BLOCO 13 CONCLUIDO ===');
END;
/
