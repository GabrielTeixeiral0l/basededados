-- =============================================================================
-- SCRIPT DE TESTES: LÓGICA DE NOTAS E PAGAMENTOS (CORRIGIDO V2)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sufixo VARCHAR2(10) := 'LN_'||TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    v_tur_id NUMBER; v_ins_id NUMBER; v_mat_id NUMBER;
    v_ava_pai_id NUMBER; v_ava_f1_id NUMBER; v_ava_f2_id NUMBER;
    v_tav_id NUMBER; v_uc_id NUMBER; v_doc_id NUMBER;
    v_curso_id NUMBER; v_est_id NUMBER;
    v_nota_pai NUMBER; v_nota_final NUMBER;
    v_parcela_id NUMBER; v_valor_parcela NUMBER;
    v_estado_antes CHAR(1); v_estado_depois CHAR(1);
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES DE LÓGICA DE NEGÓCIO ===');

    -- 1. SETUP RÁPIDO
    SELECT MIN(id) INTO v_curso_id FROM curso;
    SELECT MIN(id) INTO v_est_id FROM estudante;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('Lógica '||v_sufixo, 'LOG'||v_sufixo, 40, 20) RETURNING id INTO v_uc_id;
    
    INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel)
    VALUES ('Docente '||v_sufixo, SYSDATE, SUBSTR('3'||v_sufixo||'000',1,9), '123456789ZZ5', 'd@l.com', '910000000') 
    RETURNING id INTO v_doc_id;
    
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('T_'||v_sufixo, '25/26', v_uc_id, 30, v_doc_id) RETURNING id INTO v_tur_id;

    INSERT INTO matricula (curso_id, estudante_id, estado_matricula_id, ano_inscricao, numero_parcelas)
    VALUES (v_curso_id, v_est_id, 1, 2025, 10)
    RETURNING id INTO v_mat_id;

    INSERT INTO inscricao (turma_id, matricula_id, data)
    VALUES (v_tur_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins_id;

    -- 2. TESTE DE AGREGAÇÃO DE NOTAS
    DBMS_OUTPUT.PUT_LINE('1. Testando Agregação de Notas (Exemplos Variados)...');
    
    SELECT MIN(id) INTO v_tav_id FROM tipo_avaliacao WHERE permite_filhos = '1';

    -- Exemplo 1: Aluno com média 16 (40% de 10 + 60% de 20)
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Avaliação A', SYSDATE, SYSDATE, 100, 1, v_tur_id, v_tav_id) RETURNING id INTO v_ava_pai_id;

    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, avaliacao_pai_id)
    VALUES ('F1 (40%)', SYSDATE, SYSDATE, 40, 1, v_tur_id, v_tav_id, v_ava_pai_id) RETURNING id INTO v_ava_f1_id;

    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, avaliacao_pai_id)
    VALUES ('F2 (60%)', SYSDATE, SYSDATE, 60, 1, v_tur_id, v_tav_id, v_ava_pai_id) RETURNING id INTO v_ava_f2_id;

    INSERT INTO nota (inscricao_id, avaliacao_id, nota) VALUES (v_ins_id, v_ava_f1_id, 10); 
    INSERT INTO nota (inscricao_id, avaliacao_id, nota) VALUES (v_ins_id, v_ava_f2_id, 20);  

    SELECT nota INTO v_nota_pai FROM nota WHERE inscricao_id = v_ins_id AND avaliacao_id = v_ava_pai_id;
    DBMS_OUTPUT.PUT_LINE('[OK] Exemplo 1 (Pai A): Nota ' || v_nota_pai || ' (Esperado 16)');

    -- Exemplo 2: Outra avaliação para o mesmo aluno (Peso 50/50)
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Avaliação B', SYSDATE, SYSDATE, 100, 1, v_tur_id, v_tav_id) RETURNING id INTO v_ava_pai_id;

    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, avaliacao_pai_id)
    VALUES ('F1 (50%)', SYSDATE, SYSDATE, 50, 1, v_tur_id, v_tav_id, v_ava_pai_id) RETURNING id INTO v_ava_f1_id;

    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, avaliacao_pai_id)
    VALUES ('F2 (50%)', SYSDATE, SYSDATE, 50, 1, v_tur_id, v_tav_id, v_ava_pai_id) RETURNING id INTO v_ava_f2_id;

    INSERT INTO nota (inscricao_id, avaliacao_id, nota) VALUES (v_ins_id, v_ava_f1_id, 18); 
    INSERT INTO nota (inscricao_id, avaliacao_id, nota) VALUES (v_ins_id, v_ava_f2_id, 12);  

    SELECT nota INTO v_nota_pai FROM nota WHERE inscricao_id = v_ins_id AND avaliacao_id = v_ava_pai_id;
    DBMS_OUTPUT.PUT_LINE('[OK] Exemplo 2 (Pai B): Nota ' || v_nota_pai || ' (Esperado 15)');


    -- 3. TESTE DE TESOURARIA (PAGAMENTO)
    DBMS_OUTPUT.PUT_LINE('2. Testando Liquidação de Parcela...');
    
    SELECT COUNT(*) INTO v_count FROM parcela_propina WHERE matricula_id = v_mat_id;
    
    IF v_count > 0 THEN
        SELECT id, estado, valor INTO v_parcela_id, v_estado_antes, v_valor_parcela
        FROM parcela_propina 
        WHERE matricula_id = v_mat_id AND numero = 1;

        -- Pagar parcela (Nome correto: PRC_PROCESSAR_PAGAMENTO)
        PKG_TESOURARIA.PRC_PROCESSAR_PAGAMENTO(v_parcela_id, v_valor_parcela);

        SELECT estado INTO v_estado_depois FROM parcela_propina WHERE id = v_parcela_id;

        IF v_estado_depois = 'P' THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Parcela liquidada com sucesso (Estado mudou para P).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] Estado da parcela incorreto. Antes: '||v_estado_antes||', Depois: '||v_estado_depois);
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Nenhuma parcela gerada para a matrícula '||v_mat_id);
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== TESTES DE LÓGICA FINALIZADOS ===');

EXCEPTION WHEN OTHERS THEN
    -- ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
