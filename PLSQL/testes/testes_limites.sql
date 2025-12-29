-- =============================================================================
-- TESTE DE LIMITES DE ECTS (Versão Final DDLv3)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_est_id NUMBER;
    v_mat_id NUMBER;
    v_curso_id NUMBER;
    v_count_log NUMBER;
    v_sufixo VARCHAR2(10) := TRIM(TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999))));
    
    PROCEDURE T_INS(p_mat_id NUMBER, p_ects NUMBER, p_nome VARCHAR2, p_sfx VARCHAR2) IS
        v_u_id NUMBER;
        v_t_id NUMBER;
        v_cur_id NUMBER;
        v_doc_id NUMBER;
    BEGIN
        SELECT curso_id INTO v_cur_id FROM matricula WHERE id = p_mat_id;
        SELECT id INTO v_doc_id FROM (SELECT id FROM docente ORDER BY id) WHERE ROWNUM = 1;

        INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status) 
        VALUES (p_nome, 'UC'||p_sfx||seq_unidade_curricular.NEXTVAL, 10, 10, '1')
        RETURNING id INTO v_u_id;
        
        INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, status)
        VALUES (v_cur_id, v_u_id, 1, 1, p_ects, '0', '1');

        INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status)
        VALUES ('T'||v_u_id, '2025', v_u_id, v_doc_id, '1')
        RETURNING id INTO v_t_id;

        INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_t_id, p_mat_id, SYSDATE, '1');
        DBMS_OUTPUT.PUT_LINE('-> Inscricao OK ('||p_ects||' ECTS).');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('-> Bloqueio esperado: '||SQLERRM);
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTANDO LIMITES DE ECTS ===');

    INSERT INTO estudante (nome, data_nascimento, cc, nif, email, telemovel, status) 
    VALUES ('Aluno L '||v_sufixo, TO_DATE('2000-01-01', 'YYYY-MM-DD'), 
            '1'||v_sufixo||'000', '2'||v_sufixo||'0000', 
            'l'||v_sufixo||'@t.com', '912345678', '1')
    RETURNING id INTO v_est_id;
    
    SELECT id INTO v_curso_id FROM (SELECT id FROM curso ORDER BY id) WHERE ROWNUM = 1;
    
    -- DDLv3: estado_matricula, numero_parcelas
    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status)
    VALUES (v_curso_id, 2025, v_est_id, 'Ativa', 10, '1')
    RETURNING id INTO v_mat_id;

    T_INS(v_mat_id, 30, 'UC_A', v_sufixo);
    T_INS(v_mat_id, 35, 'UC_B', v_sufixo); -- Total 65 > 60
    
    SELECT COUNT(*) INTO v_count_log FROM log 
    WHERE tabela = 'INSCRICAO' AND acao = 'ERRO' AND data LIKE '%Limite%ECTS%';

    IF v_count_log > 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE DE LIMITES: SUCESSO ===');
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE DE LIMITES: ALERTA NAO ENCONTRADO NO LOG ===');
    END IF;

    ROLLBACK;
END;
/
