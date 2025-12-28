-- =============================================================================
-- TESTE DE LIMITES DE ECTS
-- Verifica se o sistema gera alerta para inscrições acima de 60 ECTS.
-- =============================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_est_id NUMBER;
    v_mat_id NUMBER;
    v_curso_id NUMBER;
    v_total_ects NUMBER := 0;
    v_count_log NUMBER;
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    
    PROCEDURE TENTAR_INSCRICAO(p_mat_id NUMBER, p_ects NUMBER, p_nome_uc VARCHAR2) IS
        v_u_id NUMBER;
        v_t_id NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('-> Criando UC ' || p_nome_uc || ' com ' || p_ects || ' ECTS...');
        
        -- 1. Criar UC
        INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
        VALUES (p_nome_uc, SUBSTR(p_nome_uc, 1, 10)||v_sufixo||seq_unidade_curricular.NEXTVAL, 10, 10)
        RETURNING id INTO v_u_id;
        
        -- 2. Associar ao Curso
        INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria)
        VALUES ((SELECT curso_id FROM matricula WHERE id = p_mat_id), v_u_id, 1, 1, p_ects, '0');

        -- 3. Criar Turma (Buscar docente existente)
        DECLARE
            v_doc_id NUMBER;
        BEGIN
            SELECT id INTO v_doc_id FROM (SELECT id FROM docente ORDER BY id) WHERE ROWNUM = 1;
            
            INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id)
            VALUES ('T_'||v_u_id, '2025/26', v_u_id, v_doc_id)
            RETURNING id INTO v_t_id;
        END;

        -- 4. Tentar Inscrição
        INSERT INTO inscricao (turma_id, matricula_id, data) 
        VALUES (v_t_id, p_mat_id, SYSDATE);
        
        v_total_ects := v_total_ects + p_ects;
        DBMS_OUTPUT.PUT_LINE('[INFO] Inscrição realizada. Total Acumulado: ' || v_total_ects);
        
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[ALERTA/ERRO] Capturado: '||SQLERRM);
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTANDO LIMITES DE ECTS ===');

    -- 1. Criar Estudante (Deixar trigger atribuir ID)
    INSERT INTO estudante (nome, data_nascimento, cc, nif, email, telemovel) 
    VALUES ('Aluno Limite '||v_sufixo, TO_DATE('2000-01-01', 'YYYY-MM-DD'), 
            SUBSTR(v_sufixo||'999999',1,12), SUBSTR('99'||v_sufixo||'00',1,9), 
            'limite'||v_sufixo||'@teste.com', '912345678')
    RETURNING id INTO v_est_id;
    
    DBMS_OUTPUT.PUT_LINE('Estudante criado ID: ' || v_est_id);

    -- 2. Obter Curso
    SELECT id INTO v_curso_id FROM (SELECT id FROM curso ORDER BY id) WHERE ROWNUM = 1;
    
    -- 3. Criar Matrícula
    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas)
    VALUES (v_curso_id, 2025, v_est_id, 'Ativa', 10)
    RETURNING id INTO v_mat_id;

    -- 4. Testes de Inscrição
    TENTAR_INSCRICAO(v_mat_id, 30, 'Cadeira_A'); -- Total 30
    TENTAR_INSCRICAO(v_mat_id, 25, 'Cadeira_B'); -- Total 55
    
    DBMS_OUTPUT.PUT_LINE('Tentando inscrever +10 ECTS (Total seria 65)...');
    TENTAR_INSCRICAO(v_mat_id, 10, 'Cadeira_C'); -- Total 65

    -- COMMIT para garantir que os logs (se disparados por triggers normais) estão lá
    -- Embora PKG_LOG use autonomous transaction, o COMMIT ajuda na consistência do teste
    COMMIT;

    -- Verificação via LOG
    SELECT COUNT(*) INTO v_count_log 
    FROM log 
    WHERE data LIKE '%Limite de '||PKG_CONSTANTES.LIMITE_ECTS_ANUAL||' ECTS%'
      AND data LIKE '%'||v_mat_id||'%';

    IF v_count_log > 0 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE DE LIMITES: SUCESSO (Alerta detetado no LOG) ===');
    ELSE
        -- Debug: Mostrar os últimos logs se falhar
        DBMS_OUTPUT.PUT_LINE('=== TESTE DE LIMITES: FALHA (Alerta não detetado no LOG para matricula '||v_mat_id||') ===');
    END IF;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERRO FATAL NO TESTE DE LIMITES: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
END;
/
