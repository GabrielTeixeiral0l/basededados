-- =============================================================================
-- TESTES FUNCIONAIS EXTRA
-- Cobre: PKG_TESOURARIA (Multas), TRG_VAL_NOTA, PKG_LOG (Flag)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    v_est_id NUMBER; v_cur_id NUMBER; v_mat_id NUMBER;
    v_ins_id NUMBER; v_uc_id NUMBER; v_tur_id NUMBER; v_ava_id NUMBER;
    v_parcela_id NUMBER;
    v_valor_original NUMBER; v_valor_final NUMBER;
    v_log_antes NUMBER; v_log_depois NUMBER;
    v_tc_id NUMBER; v_doc_id NUMBER; v_tav_id NUMBER;
    v_count_not_null NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES FUNCIONAIS EXTRA (Sufixo: '||v_sufixo||') ===');

    -- 1. Setup Seguro
    BEGIN
        SELECT id INTO v_tc_id FROM (SELECT id FROM tipo_curso ORDER BY id) WHERE ROWNUM = 1;
        SELECT id INTO v_tav_id FROM (SELECT id FROM tipo_avaliacao ORDER BY id) WHERE ROWNUM = 1;
        SELECT id INTO v_doc_id FROM (SELECT id FROM docente ORDER BY id) WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[ERRO] Setup falhou: Certifique-se que existem tipos de curso, avaliação e docentes.');
        RETURN;
    END;

    -- 2. Criar Estudante, Curso e Matrícula
    INSERT INTO estudante (nome, cc, nif, email, telemovel, data_nascimento, iban)
    VALUES ('Aluno Extra '||v_sufixo, '12345678', '275730972', 'extra@teste.com', '910000000', SYSDATE-7000, 'PT50000000000000000000000')
    RETURNING id INTO v_est_id;

    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id)
    VALUES ('Curso Extra '||v_sufixo, 'CE'||v_sufixo, 'Desc', 3, 180, v_tc_id) RETURNING id INTO v_cur_id;

    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas)
    VALUES (v_cur_id, v_est_id, 'Ativa', 2025, 1) RETURNING id INTO v_mat_id;

    -- -------------------------------------------------------------------------
    -- TESTE 1: MULTA POR ATRASO (PKG_TESOURARIA)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('1. Testando Multa por Atraso...');
    
    SELECT id, valor INTO v_parcela_id, v_valor_original FROM parcela_propina WHERE matricula_id = v_mat_id AND numero = 1;
    
    -- Simular atraso
    UPDATE parcela_propina SET data_vencimento = SYSDATE - 10 WHERE id = v_parcela_id;
    
    -- Processar pagamento
    PKG_TESOURARIA.PRC_PROCESSAR_PAGAMENTO(v_parcela_id, v_valor_original);
    
    SELECT valor INTO v_valor_final FROM parcela_propina WHERE id = v_parcela_id;
    
    IF v_valor_final > v_valor_original THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Multa aplicada. Original: '||v_valor_original||', Final: '||v_valor_final);
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Multa não aplicada (Verificar PKG_CONSTANTES.TAXA_MULTA_ATRASO).');
    END IF;

    -- -------------------------------------------------------------------------
    -- TESTE 2: VALIDAÇÃO DE NOTA (0-20)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('2. Testando Limites de Nota (0-20)...');
    
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) VALUES ('UC Extra', 'UCE'||v_sufixo, 10, 10) RETURNING id INTO v_uc_id;
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id) VALUES ('TE'||v_sufixo, '25/26', v_uc_id, v_doc_id) RETURNING id INTO v_tur_id;
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins_id;
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id) VALUES ('Teste', SYSDATE, SYSDATE, 10, 1, v_tur_id, v_tav_id) RETURNING id INTO v_ava_id;

    -- Tentar inserir nota inválida (25)
    BEGIN
        INSERT INTO nota (inscricao_id, avaliacao_id, nota) VALUES (v_ins_id, v_ava_id, 25);
        DBMS_OUTPUT.PUT_LINE('[FALHA] Nota invalida permitida.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Nota invalida bloqueada.');
    END;

    SELECT COUNT(*) INTO v_count_not_null FROM log WHERE acao = 'ERRO' AND data LIKE '%nota invalida%' AND created_at > SYSDATE - 1/24;
    
    IF v_count_not_null > 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] Log de erro encontrado.'); 
    ELSE DBMS_OUTPUT.PUT_LINE('[FALHA] Nota inválida não gerou log de erro.'); END IF;

    -- -------------------------------------------------------------------------
    -- TESTE 3: FLAG DE AUDITORIA
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('3. Testando Flag de Auditoria (v_audit_enabled)...');
    
    PKG_LOG.v_audit_enabled := FALSE;
    SELECT COUNT(*) INTO v_log_antes FROM log;
    
    -- Esta ação não deve gerar log porque a flag está FALSE
    PKG_LOG.REGISTAR('INFO_TESTE', 'Ignora-me', 'SALA');
    
    SELECT COUNT(*) INTO v_log_depois FROM log;
    
    IF v_log_depois = v_log_antes THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Flag v_audit_enabled = FALSE respeitada.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Log foi gravado mesmo com flag desativada.');
    END IF;
    
    -- Erro crítico deve ser gravado mesmo com flag FALSE
    PKG_LOG.ERRO('ERRO_CRITICO_TESTE');
    SELECT COUNT(*) INTO v_log_depois FROM log;
    
    IF v_log_depois > v_log_antes THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Erro crítico gravado mesmo com auditoria desativada.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Erro crítico foi ignorado.');
    END IF;

    PKG_LOG.v_audit_enabled := TRUE; -- Reativar
    DBMS_OUTPUT.PUT_LINE('=== FIM DOS TESTES FUNCIONAIS EXTRA ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO NOS TESTES EXTRA !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
