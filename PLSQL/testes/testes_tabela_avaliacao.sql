-- =============================================================================
-- TESTE UNITÁRIO: TABELA AVALIACAO
-- Regras: Status, Peso, Datas, Requer Entrega
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_ava_id NUMBER;
    v_status_final VARCHAR2(1);
    v_peso_final NUMBER;
    v_dt_entrega DATE;
    v_tipo_com_entrega NUMBER;
    v_tipo_sem_entrega NUMBER;
    v_turma_id NUMBER;
    v_count_erros NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA AVALIACAO ===');

    -- 1. Setup
    SELECT id INTO v_turma_id FROM (SELECT id FROM turma ORDER BY id) WHERE ROWNUM = 1;
    
    -- Criar tipos específicos para teste
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) 
    VALUES ('Teste Com Entrega', '1', '1', '1') RETURNING id INTO v_tipo_com_entrega;
    
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) 
    VALUES ('Teste Sem Entrega', '0', '1', '1') RETURNING id INTO v_tipo_sem_entrega;

    -- 2. Teste Status e Peso Inválido
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido e Peso > 1...');
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
    VALUES ('Aval Teste 1', SYSDATE, SYSDATE+1, 1.5, 1, v_turma_id, v_tipo_com_entrega, 'X')
    RETURNING id, status, peso INTO v_ava_id, v_status_final, v_peso_final;

    IF v_status_final = '0' THEN DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido.'); ELSE 
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status nao corrigido: '||v_status_final); v_count_erros := v_count_erros + 1; END IF;
    IF v_peso_final = 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] Peso corrigido para 0.'); ELSE 
        DBMS_OUTPUT.PUT_LINE('[FALHA] Peso nao corrigido: '||v_peso_final); v_count_erros := v_count_erros + 1; END IF;

    -- 3. Teste Datas Invertidas (Entrega < Inicio)
    DBMS_OUTPUT.PUT_LINE('2. Testando Data Entrega anterior ao inicio...');
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Aval Teste 2', SYSDATE+5, SYSDATE, 0.5, 1, v_turma_id, v_tipo_com_entrega)
    RETURNING id, data_entrega INTO v_ava_id, v_dt_entrega;

    IF v_dt_entrega >= SYSDATE+5 THEN DBMS_OUTPUT.PUT_LINE('[OK] Data entrega ajustada.'); ELSE 
        DBMS_OUTPUT.PUT_LINE('[FALHA] Data entrega mantida no passado.'); v_count_erros := v_count_erros + 1; END IF;

    -- 4. Teste Tipo Sem Entrega (Forçar NULL)
    DBMS_OUTPUT.PUT_LINE('3. Testando Tipo que nao requer entrega...');
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Aval Teste 3', SYSDATE, SYSDATE+10, 0.5, 1, v_turma_id, v_tipo_sem_entrega)
    RETURNING id, data_entrega INTO v_ava_id, v_dt_entrega;

    IF v_dt_entrega IS NULL THEN DBMS_OUTPUT.PUT_LINE('[OK] Data entrega forçada a NULL.'); ELSE 
        DBMS_OUTPUT.PUT_LINE('[FALHA] Data entrega não é NULL.'); v_count_erros := v_count_erros + 1; END IF;

    -- Resumo
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE AVALIACAO: SUCESSO ===');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE AVALIACAO: FALHOU (' || v_count_erros || ' erros) ===');
        ROLLBACK;
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE AVALIACAO !!! ' || SQLERRM);
    ROLLBACK;
END;
/
