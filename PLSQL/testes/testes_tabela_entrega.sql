-- =============================================================================
-- TESTE UNITÁRIO: TABELA ENTREGA
-- Regras: Status, Prazos, Requisito de Entrega
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_tipo_aval_com_entrega NUMBER;
    v_tipo_aval_sem_entrega NUMBER;
    v_turma_id NUMBER;
    v_aval_id NUMBER;
    v_aval_no_sub_id NUMBER;
    v_entrega_id NUMBER;
    v_status VARCHAR2(1);
    v_count_erros NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA ENTREGA ===');

    -- SETUP DE DADOS
    -- 1. Obter ou Criar Tipos de Avaliação
    BEGIN
        SELECT id INTO v_tipo_aval_com_entrega FROM tipo_avaliacao WHERE requer_entrega = '1' AND ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO tipo_avaliacao (id, nome, requer_entrega, permite_grupo, permite_filhos, status)
        VALUES (9998, 'Projecto Teste', '1', '1', '0', '1') RETURNING id INTO v_tipo_aval_com_entrega;
    END;

    BEGIN
        SELECT id INTO v_tipo_aval_sem_entrega FROM tipo_avaliacao WHERE requer_entrega = '0' AND ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO tipo_avaliacao (id, nome, requer_entrega, permite_grupo, permite_filhos, status)
        VALUES (9999, 'Exame Teste', '0', '0', '0', '1') RETURNING id INTO v_tipo_aval_sem_entrega;
    END;

    -- 2. Obter uma Turma qualquer (assume-se que base de dados tem dados iniciais)
    BEGIN
        SELECT id INTO v_turma_id FROM turma WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('!!! FALHA DE SETUP: Nenhuma turma encontrada. Execute o DML primeiro.');
        RETURN;
    END;

    -- 3. Criar Avaliação (Prazo Passado)
    -- Data inicio: 10 dias atras. Data fim: 5 dias atras.
    INSERT INTO avaliacao (id, titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
    VALUES (99999, 'Avaliacao Teste Prazo', SYSDATE - 10, SYSDATE - 5, 0.5, 2, v_turma_id, v_tipo_aval_com_entrega, '1')
    RETURNING id INTO v_aval_id;

    -- 4. Criar Avaliação (Sem Entrega)
    INSERT INTO avaliacao (id, titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
    VALUES (99998, 'Avaliacao Sem Entrega', SYSDATE - 10, NULL, 0.5, 1, v_turma_id, v_tipo_aval_sem_entrega, '1')
    RETURNING id INTO v_aval_no_sub_id;


    -- TESTE 1: Status Inválido
    DBMS_OUTPUT.PUT_LINE('1. Testando Status Inválido (Inserir "X")...');
    -- Data de entrega valida (dentro do prazo passado)
    INSERT INTO entrega (data_entrega, avaliacao_id, status)
    VALUES (SYSDATE - 6, v_aval_id, 'X') 
    RETURNING id, status INTO v_entrega_id, v_status;

    IF v_status = '0' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Status corrigido para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Status nao corrigido: ' || v_status);
        v_count_erros := v_count_erros + 1;
    END IF;

    -- TESTE 2: Entrega Fora do Prazo (Atraso)
    DBMS_OUTPUT.PUT_LINE('2. Testando Entrega Fora do Prazo (Hoje > Prazo -5 dias)...');
    INSERT INTO entrega (data_entrega, avaliacao_id, status)
    VALUES (SYSDATE, v_aval_id, '1'); 
    DBMS_OUTPUT.PUT_LINE('[OK] Insercao realizada. Verificar LOG para ALERTA de "Entrega FORA DO PRAZO".');

    -- TESTE 3: Entrega Antes do Inicio
    DBMS_OUTPUT.PUT_LINE('3. Testando Entrega Antes do Inicio (-15 dias < Inicio -10 dias)...');
    INSERT INTO entrega (data_entrega, avaliacao_id, status)
    VALUES (SYSDATE - 15, v_aval_id, '1'); 
    DBMS_OUTPUT.PUT_LINE('[OK] Insercao realizada. Verificar LOG para ALERTA de "Entrega efetuada ANTES".');

    -- TESTE 4: Entrega não requerida
    DBMS_OUTPUT.PUT_LINE('4. Testando Entrega em Avaliação que não requer ficheiros...');
    INSERT INTO entrega (data_entrega, avaliacao_id, status)
    VALUES (SYSDATE, v_aval_no_sub_id, '1');
    DBMS_OUTPUT.PUT_LINE('[OK] Insercao realizada. Verificar LOG para ALERTA de "nao requer entrega".');

    -- CLEANUP / ROLLBACK
    ROLLBACK;
    
    IF v_count_erros = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE ENTREGA: SUCESSO (ROLLBACK EXECUTADO) ===');
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE ENTREGA: FALHOU (' || v_count_erros || ' erros) ===');
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE ENTREGA !!! ' || SQLERRM);
    ROLLBACK;
END;
/
