-- =============================================================================
-- SCRIPT DE TESTES AVANÇADOS (REGRAS DE NEGÓCIO E INTEGRIDADE)
-- =============================================================================
SET SERVEROUTPUT ON;
SET FEEDBACK OFF;

DECLARE
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    v_est_id NUMBER; v_cur_id NUMBER; v_mat_id NUMBER;
    v_uc_id NUMBER; v_doc_id NUMBER; v_tur_id NUMBER;
    v_aul1_id NUMBER; v_aul2_id NUMBER; v_sal_id NUMBER;
    v_ta_id NUMBER; v_tc_id NUMBER; v_em_id NUMBER;
    v_log_count NUMBER;
    v_valor_parcela NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES AVANÇADOS (Sufixo: '||v_sufixo||') ===');

    -- 1. TESTE DE VALIDAÇÃO DE DOCUMENTOS (NIF INVÁLIDO)
    DBMS_OUTPUT.PUT_LINE('1. Testando NIF Inválido...');
    INSERT INTO estudante (nome, morada, data_nascimento, cc, nif, email, telemovel)
    VALUES ('Aluno Erro '||v_sufixo, 'Rua B', SYSDATE-7000, 
            SUBSTR('CC'||v_sufixo||'000',1,12), '123456780', -- NIF Inválido (checksum errado)
            'e'||v_sufixo||'@erro.com', '96'||SUBSTR(v_sufixo,1,7))
    RETURNING id INTO v_est_id;

    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ALERTA' AND "DATA" LIKE '%NIF inválido%';
    
    IF v_log_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Trigger de validação de NIF detectou erro e registou log.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Trigger de validação de NIF não registou o alerta.');
    END IF;

    -- 2. TESTE DE GERAÇÃO AUTOMÁTICA DE PROPINAS E PARCELAS
    DBMS_OUTPUT.PUT_LINE('2. Testando Plano de Pagamento...');
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('Lic '||v_sufixo, 1200) RETURNING id INTO v_tc_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id)
    VALUES ('Curso Teste '||v_sufixo, 'CT'||v_sufixo, 'Desc', 3, 180, 30, v_tc_id)
    RETURNING id INTO v_cur_id;

    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas)
    VALUES (v_cur_id, v_est_id, 'Ativa', 2025, 12)
    RETURNING id INTO v_mat_id;

    SELECT COUNT(*) INTO v_log_count FROM parcela_propina WHERE matricula_id = v_mat_id;
    SELECT SUM(valor) INTO v_valor_parcela FROM parcela_propina WHERE matricula_id = v_mat_id;

    IF v_log_count = 12 AND v_valor_parcela = 1200 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Plano de pagamento gerado: 12 parcelas, total 1200€.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Erro na geração do plano de pagamento. Total: '||v_valor_parcela);
    END IF;

    -- 3. TESTE DE CONFLITO DE HORÁRIO (DOCENTE)
    DBMS_OUTPUT.PUT_LINE('3. Testando Conflito de Horário...');
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
    VALUES ('UC Teste '||v_sufixo, 'UT'||v_sufixo, 40, 20) RETURNING id INTO v_uc_id;
    
    INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel)
    VALUES ('Prof Conflito '||v_sufixo, SYSDATE, SUBSTR('2'||v_sufixo||'9999',1,9), 
            SUBSTR(v_sufixo||'XY00000',1,12), 'd'||v_sufixo||'@test.com', '92'||SUBSTR(v_sufixo,1,7))
    RETURNING id INTO v_doc_id;

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('Turma A '||v_sufixo, '25/26', v_uc_id, 20, v_doc_id) RETURNING id INTO v_tur_id;

    INSERT INTO tipo_aula (nome) VALUES ('Teorica '||v_sufixo) RETURNING id INTO v_ta_id;
    INSERT INTO sala (nome, capacidade) VALUES ('Sala X '||v_sufixo, 30) RETURNING id INTO v_sal_id;

    -- Aula 1: 10:00 - 12:00
    INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
    VALUES (TRUNC(SYSDATE)+1, TO_DATE('10:00','HH24:MI'), TO_DATE('12:00','HH24:MI'), 'Aula 1', v_ta_id, v_sal_id, v_tur_id)
    RETURNING id INTO v_aul1_id;

    -- Aula 2 (Mesmo Docente, mesmo horário): 11:00 - 13:00
    INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
    VALUES (TRUNC(SYSDATE)+1, TO_DATE('11:00','HH24:MI'), TO_DATE('13:00','HH24:MI'), 'Aula 2 Conflito', v_ta_id, v_sal_id, v_tur_id)
    RETURNING id INTO v_aul2_id;

    COMMIT; -- Garantir que a transação autónoma do log foi persistida

    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ALERTA' AND "DATA" LIKE '%Conflito de horario%';

    IF v_log_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Trigger detectou conflito de horário do docente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Conflito de horário não detectado.');
    END IF;

    -- 4. TESTE DE SOFT-DELETE
    DBMS_OUTPUT.PUT_LINE('4. Testando Soft-Delete...');
    PKG_GESTAO_DADOS.PRC_REMOVER('ESTUDANTE', v_est_id);
    
    DECLARE
        v_status CHAR(1);
    BEGIN
        SELECT status INTO v_status FROM estudante WHERE id = v_est_id;
        IF v_status = '0' THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Estudante marcado como inativo (soft-delete).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] Estudante continua ativo após remoção.');
        END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[AVISO] Estudante foi removido fisicamente. Verifique configuração.');
    END;

    COMMIT; 
    DBMS_OUTPUT.PUT_LINE('=== TESTES AVANÇADOS FINALIZADOS ===');

EXCEPTION WHEN OTHERS THEN
    -- ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NOS TESTES !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
