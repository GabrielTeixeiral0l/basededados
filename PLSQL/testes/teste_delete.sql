SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;

PROMPT ========================================================
PROMPT   INICIANDO TESTE GLOBAL DE ELIMINACAO (V13 - CLEAN)
PROMPT ========================================================

DECLARE
    v_sfx VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999)));
    v_cur_id NUMBER; v_uc_id NUMBER; v_doc_id NUMBER; 
    v_mat_id NUMBER; v_ins_id NUMBER; v_aul_id NUMBER;
    v_tc_id  NUMBER; v_sal_id NUMBER; v_tur_id NUMBER; v_ta_id NUMBER;
    v_est_id NUMBER;
    
    v_nif_est VARCHAR2(9) := '234567890';
    v_nif_doc VARCHAR2(9) := '501306000';
    v_tel     VARCHAR2(9) := '912345678';
    v_cc      VARCHAR2(12):= '123456789ZZ1'; -- Atualizado para 12 chars conforme nova regra

    PROCEDURE verificar_log(p_tab VARCHAR2) IS
        v_l NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_l FROM log 
        WHERE tabela = p_tab AND acao = 'DELETE' 
        AND created_at >= SYSTIMESTAMP - INTERVAL '20' SECOND;
        
        IF v_l > 0 THEN
            DBMS_OUTPUT.PUT_LINE('[OK] ' || RPAD(p_tab, 18) || ': Soft-delete registado no Log.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] ' || RPAD(p_tab, 18) || ': Trigger não gerou log.');
        END IF;
    END;

BEGIN
    -- --- SETUP DE DADOS ---
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('TC_'||v_sfx, 1000) RETURNING id INTO v_tc_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id) 
    VALUES ('CURSO_'||v_sfx, 'C'||v_sfx, 'D', 3, 180, v_tc_id) RETURNING id INTO v_cur_id;
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('UC_'||v_sfx, 'U'||v_sfx, 20, 20) RETURNING id INTO v_uc_id;
    INSERT INTO sala (nome, capacidade) VALUES ('S_'||v_sfx, 30) RETURNING id INTO v_sal_id;
    
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria) 
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '0');
    
    INSERT INTO docente (nome, nif, cc, data_contratacao, email, telemovel) 
    VALUES ('DOCENTE TESTE', v_nif_doc, v_cc, SYSDATE-30, 'd'||v_sfx||'@t.pt', v_tel) RETURNING id INTO v_doc_id;
    
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, status) VALUES (v_uc_id, v_doc_id, '1');
    
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id) 
    VALUES ('T_'||v_sfx, '2025', v_uc_id, v_doc_id) RETURNING id INTO v_tur_id;
    
    INSERT INTO tipo_aula (nome) VALUES ('TA_'||v_sfx) RETURNING id INTO v_ta_id;
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, tipo_aula_id, turma_id) 
    VALUES (TRUNC(SYSDATE), TRUNC(SYSDATE)+10/24, TRUNC(SYSDATE)+12/24, v_sal_id, v_ta_id, v_tur_id) RETURNING id INTO v_aul_id;

    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel) 
    VALUES ('ALUNO TESTE', v_nif_est, v_cc, TO_DATE('2000-01-01','YYYY-MM-DD'), 'e'||v_sfx||'@t.pt', v_tel) RETURNING id INTO v_est_id;
    
    INSERT INTO matricula (curso_id, estudante_id, ano_inscricao, estado_matricula, numero_parcelas) 
    VALUES (v_cur_id, v_est_id, 2025, 'Ativa', 10) RETURNING id INTO v_mat_id;
    
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins_id;
    -- A presença é gerada automaticamente pelo trigger da Aula ou Inscrição

    DBMS_OUTPUT.PUT_LINE('1. Setup de dados completo.');

    -- --- FASE DE ELIMINAÇÃO (ORDEM HIERÁRQUICA) ---
    DBMS_OUTPUT.PUT_LINE('--- INICIANDO TESTES DE DELETE ---');

    -- 1. Eliminar Presença
    DELETE FROM presenca WHERE aula_id = v_aul_id AND inscricao_id = v_ins_id;
    verificar_log('PRESENCA');

    -- 2. Eliminar Aula
    DELETE FROM aula WHERE id = v_aul_id;
    verificar_log('AULA');

    -- 3. Eliminar Inscrição
    DELETE FROM inscricao WHERE id = v_ins_id;
    verificar_log('INSCRICAO');

    -- 4. Eliminar Turma
    DELETE FROM turma WHERE id = v_tur_id;
    verificar_log('TURMA');

    -- 5. Eliminar Sala
    DELETE FROM sala WHERE id = v_sal_id;
    verificar_log('SALA');

    -- 6. Eliminar Relação UC_DOCENTE
    DELETE FROM uc_docente WHERE unidade_curricular_id = v_uc_id AND docente_id = v_doc_id;
    verificar_log('UC_DOCENTE');

    DBMS_OUTPUT.PUT_LINE('========================================================');
    DBMS_OUTPUT.PUT_LINE('   TESTE FINALIZADO COM SUCESSO');
    DBMS_OUTPUT.PUT_LINE('========================================================');

    ROLLBACK; 

EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('!!! ERRO DURANTE O TESTE !!!');
    DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Trace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/