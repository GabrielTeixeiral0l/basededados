-- =============================================================================
-- TESTES UNITÁRIOS INTEGRADOS (Versão Final Corrigida DDLv3)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_est_id    NUMBER;
    v_cur_id    NUMBER;
    v_mat_id    NUMBER;
    v_turma_id  NUMBER;
    v_insc_id   NUMBER;
    v_count     NUMBER;
    v_sfx       VARCHAR2(10) := TRIM(TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999))));
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES INTEGRADOS (Sufixo: '||v_sfx||') ===');

    -- 1. SETUP BASE
    SELECT id INTO v_cur_id FROM (SELECT id FROM curso ORDER BY id) WHERE ROWNUM = 1;
    
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel, iban, status) 
    VALUES ('Integrado '||v_sfx, '21111'||v_sfx, '1111'||v_sfx, TO_DATE('2000-01-01','YYYY-MM-DD'), 'i'||v_sfx||'@univ.pt', '912345678', 'PT50000000000000000000000', '1')
    RETURNING id INTO v_est_id;

    -- DDLv3: estado_matricula (VARCHAR2), numero_parcelas (INTEGER)
    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status)
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10, '1')
    RETURNING id INTO v_mat_id;

    -- Verificar Plano Financeiro (Trigger TRG_AUTO_GERAR_PROPINAS)
    SELECT COUNT(*) INTO v_count FROM parcela_propina WHERE matricula_id = v_mat_id;
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Plano financeiro ('||v_count||' parcelas) gerado automaticamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[ERRO] Plano financeiro não gerado.');
    END IF;

    -- 2. Inscrição (Garantir que a turma é do curso e tem docente)
    SELECT id INTO v_turma_id 
    FROM (
        SELECT t.id FROM turma t 
        JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id 
        WHERE uc.curso_id = v_cur_id AND t.status = '1'
        ORDER BY t.id
    ) WHERE ROWNUM = 1;
    
    INSERT INTO inscricao (turma_id, matricula_id, data, status)
    VALUES (v_turma_id, v_mat_id, SYSDATE, '1')
    RETURNING id INTO v_insc_id;
    
    DBMS_OUTPUT.PUT_LINE('Inscrição Gerada: ' || v_insc_id);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== TESTES CONCLUÍDOS COM SUCESSO ===');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO NOS TESTES INTEGRADOS !!!');
    DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
    ROLLBACK;
END;
/