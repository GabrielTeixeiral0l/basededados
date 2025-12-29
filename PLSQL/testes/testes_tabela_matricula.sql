-- =============================================================================
-- TESTE UNITÁRIO: TABELA MATRICULA (Versão Corrigida V7 - Com Log Check)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx       VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999))); -- 4 digitos
    v_nif_val   VARCHAR2(9)  := '2'||v_sfx||'1111'; -- 1+4+4 = 9 digitos
    v_cc_val    VARCHAR2(12) := '1'||v_sfx||'222';  -- 1+4+3 = 8 digitos (valido)
    v_tel_val   VARCHAR2(9)  := '91'||v_sfx||'000'; -- 2+4+3 = 9 digitos
    v_doc_id    NUMBER;
    v_cur_id    NUMBER;
    v_uc1_id    NUMBER;
    v_uc2_id    NUMBER;
    v_est_id    NUMBER;
    v_mat_id    NUMBER;
    v_tur1_id   NUMBER;
    v_tur2_id   NUMBER;
    v_ins1_id   NUMBER;
    v_ins2_id   NUMBER;
    v_media_calc NUMBER;
    
    -- Variaveis de Diagnostico
    v_diag_pontos NUMBER;
    v_diag_ects   NUMBER;
    v_log_msg     VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES DA TABELA MATRICULA (18e) ===');

    -- 1. SETUP DE DADOS
    -- Garantir docente (Criar se nao existir ou usar um novo para evitar conflitos)
    INSERT INTO docente (nome, data_contratacao, nif, email, telemovel, status)
    VALUES ('Docente Mat '||v_sfx, SYSDATE-100, '1'||v_sfx||'8888', 'docm'||v_sfx||'@t.pt', '93'||v_sfx||'000', '1')
    RETURNING id INTO v_doc_id;
    
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id, status) 
    VALUES ('Curso M '||v_sfx, 'CM'||v_sfx, 'Desc', 3, 180, 1, '1') RETURNING id INTO v_cur_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status) 
    VALUES ('UC1 '||v_sfx, 'U1'||v_sfx, 30, 30, '1') RETURNING id INTO v_uc1_id;
    
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status) 
    VALUES ('UC2 '||v_sfx, 'U2'||v_sfx, 30, 30, '1') RETURNING id INTO v_uc2_id;

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca, status) 
    VALUES (v_cur_id, v_uc1_id, 1, 1, 10, '1', 75, '1');
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca, status) 
    VALUES (v_cur_id, v_uc2_id, 1, 1, 20, '1', 75, '1');

    -- Habilitar Docente para as UCs
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status) VALUES (v_uc1_id, v_doc_id, 'Docente', '1');
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status) VALUES (v_uc2_id, v_doc_id, 'Docente', '1');

    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel, status) 
    VALUES ('Aluno M '||v_sfx, v_nif_val, v_cc_val, TO_DATE('2000-01-01','YYYY-MM-DD'), 'a'||v_sfx||'@m.pt', v_tel_val, '1') 
    RETURNING id INTO v_est_id;

    -- 2. TESTES DE VALIDAÇÃO
    DBMS_OUTPUT.PUT_LINE('>> 2.1 Testando Limites de Parcelas...');
    BEGIN
        INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status) 
        VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 99, '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu 99 parcelas.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou parcelas invalidas.');
    END;

    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas, status) 
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10, '1') RETURNING id INTO v_mat_id;
    DBMS_OUTPUT.PUT_LINE('[OK] Matricula valida inserida.');

    -- 3. TESTE DE MÉDIA
    DBMS_OUTPUT.PUT_LINE('>> 2.3 Testando Calculo de Media Ponderada...');
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status) VALUES ('T1', '2025', v_uc1_id, v_doc_id, '1') RETURNING id INTO v_tur1_id;
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status) VALUES ('T2', '2025', v_uc2_id, v_doc_id, '1') RETURNING id INTO v_tur2_id;
    
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_tur1_id, v_mat_id, SYSDATE, '1') RETURNING id INTO v_ins1_id;
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_tur2_id, v_mat_id, SYSDATE, '1') RETURNING id INTO v_ins2_id;

    -- Update 1
    UPDATE inscricao SET nota_final = 10 WHERE id = v_ins1_id; 
    -- Update 2
    UPDATE inscricao SET nota_final = 16 WHERE id = v_ins2_id; 
    
    -- DIAGNÓSTICO MANUAL
    SELECT NVL(SUM(i.nota_final * uc.ects), 0), NVL(SUM(uc.ects), 0)
    INTO v_diag_pontos, v_diag_ects
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    JOIN matricula m ON i.matricula_id = m.id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id AND uc.curso_id = m.curso_id
    WHERE i.matricula_id = v_mat_id
      AND i.nota_final >= 10
      AND i.status = '1';
      
    DBMS_OUTPUT.PUT_LINE('DIAGNOSTICO: Pontos=' || v_diag_pontos || ' ECTS=' || v_diag_ects);
    
    SELECT media_geral INTO v_media_calc FROM matricula WHERE id = v_mat_id;
    
    IF v_media_calc IS NULL THEN
         DBMS_OUTPUT.PUT_LINE('[FALHA] Media e NULL. Trigger nao disparou ou falhou.');
         IF v_diag_ects > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Manual check: Media seria ' || (v_diag_pontos/v_diag_ects));
         END IF;
         
         -- Check Logs
         BEGIN
            SELECT acao INTO v_log_msg FROM (SELECT acao FROM log WHERE tabela = 'MATRICULA' ORDER BY id DESC) WHERE ROWNUM = 1;
            DBMS_OUTPUT.PUT_LINE('ULTIMO LOG MATRICULA: ' || v_log_msg);
         EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Nenhum log encontrado para MATRICULA.');
         END;
    ELSIF v_media_calc = 14 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Media ponderada calculada: 14');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Media incorreta: ' || v_media_calc || ' (Esperado 14)');
    END IF;

    ROLLBACK;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO FATAL NO SETUP 18e: ' || SQLERRM);
    ROLLBACK;
END;
/
