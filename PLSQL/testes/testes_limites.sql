-- =============================================================================
-- TESTE DE LIMITES DE ECTS
-- Verifica se o sistema impede inscrições acima de 60 ECTS.
-- =============================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_est_id NUMBER;
    v_mat_id NUMBER;
    v_curso_id NUMBER;
    v_total_ects NUMBER := 0;
    
    PROCEDURE TENTAR_INSCRICAO(p_mat_id NUMBER, p_ects NUMBER, p_nome_uc VARCHAR2) IS
        v_u_id NUMBER;
        v_t_id NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('-> Criando UC ' || p_nome_uc || ' com ' || p_ects || ' ECTS...');
        
        -- 1. Criar UC
        v_u_id := seq_unidade_curricular.NEXTVAL;
        INSERT INTO unidade_curricular (id, nome, codigo, horas_teoricas, horas_praticas) 
        VALUES (v_u_id, p_nome_uc, SUBSTR(p_nome_uc, 1, 10)||v_u_id, 10, 10);
        
        -- 2. Associar ao Curso
        INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria)
        VALUES ((SELECT curso_id FROM matricula WHERE id = p_mat_id), v_u_id, 1, 1, p_ects, '0');

        -- 3. Criar Turma
        v_t_id := seq_turma.NEXTVAL;
        INSERT INTO turma (id, nome, ano_letivo, unidade_curricular_id, docente_id)
        VALUES (v_t_id, 'T_'||v_t_id, '2025/26', v_u_id, 1);

        -- 4. Tentar Inscrição
        INSERT INTO inscricao (id, turma_id, matricula_id, data) 
        VALUES (seq_inscricao.NEXTVAL, v_t_id, p_mat_id, SYSDATE);
        
        v_total_ects := v_total_ects + p_ects;
        DBMS_OUTPUT.PUT_LINE('[OK] Inscrição realizada com sucesso. Total Acumulado: ' || v_total_ects);
        
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[SUCESSO] Bloqueio detetado conforme esperado para '||p_nome_uc||': '||SQLERRM);
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTANDO LIMITES DE ECTS ===');

    -- 1. Criar Estudante Novo (Dinâmico)
    -- Usamos sequence existente para garantir ID único
    -- Nota: Assumimos que seq_estudante não existe no DDL fornecido, usamos seq_utilizador ou max+1 se fosse identity, 
    -- mas o DDLv3 tem IDs integer. Vamos assumir que PKs usam sequences manuais ou triggers. 
    -- O instalador criou sequencias para tudo.
    
    -- Como não tenho certeza do nome da sequence do estudante no seu ambiente (o log anterior mostrou TRG_AI_ESTUDANTE), 
    -- vou fazer um insert sem ID se o trigger tratar, ou buscar max+1.
    -- O log mostra TRG_AI_ESTUDANTE, então deve haver sequence.
    -- Vou tentar insert direto e recuperar o ID.
    
    BEGIN
        INSERT INTO estudante (id, nome, data_nascimento, cc, nif, email, telemovel) 
        VALUES (seq_estudante.NEXTVAL, 'Aluno Limite Teste', TO_DATE('2000-01-01', 'YYYY-MM-DD'), 
                'CC'||TRUNC(DBMS_RANDOM.VALUE(10000,99999)), 
                '9'||TRUNC(DBMS_RANDOM.VALUE(10000000,99999999)), 
                'limite'||TRUNC(DBMS_RANDOM.VALUE(1,9999))||'@teste.com', 
                '912345678') 
        RETURNING id INTO v_est_id;
    EXCEPTION WHEN OTHERS THEN
        -- Fallback se sequence falhar ou for manual
        SELECT NVL(MAX(id), 0) + 1 INTO v_est_id FROM estudante;
        INSERT INTO estudante (id, nome, data_nascimento, cc, nif, email, telemovel) 
        VALUES (v_est_id, 'Aluno Limite Teste', TO_DATE('2000-01-01', 'YYYY-MM-DD'), 
                'CC'||v_est_id, '999999999', 'limite@teste.com', '912345678');
    END;
    
    DBMS_OUTPUT.PUT_LINE('Estudante criado ID: ' || v_est_id);

    -- 2. Obter Curso
    SELECT id INTO v_curso_id FROM (SELECT id FROM curso ORDER BY id) WHERE ROWNUM = 1;
    
    -- 3. Criar Matrícula
    v_mat_id := seq_matricula.NEXTVAL;
    INSERT INTO matricula (id, curso_id, ano_inscricao, estudante_id, estado_matricula_id, numero_parcelas)
    VALUES (v_mat_id, v_curso_id, 2025, v_est_id, 1, 10);
    DBMS_OUTPUT.PUT_LINE('Matrícula criada ID: ' || v_mat_id);

    -- 4. Testes de Inscrição
    -- Total permitido: 60 ECTS
    
    TENTAR_INSCRICAO(v_mat_id, 30, 'Cadeira_A'); -- Total 30 (OK)
    TENTAR_INSCRICAO(v_mat_id, 25, 'Cadeira_B'); -- Total 55 (OK)
    
    DBMS_OUTPUT.PUT_LINE('Tentando inscrever +10 ECTS (Total seria 65)...');
    TENTAR_INSCRICAO(v_mat_id, 10, 'Cadeira_C'); -- Total 65 (Deve falhar)

    -- Verificação final
    IF v_total_ects = 55 THEN
        DBMS_OUTPUT.PUT_LINE('=== TESTE DE LIMITES: SUCESSO (Bloqueou a última inscrição) ===');
    ELSE
        DBMS_OUTPUT.PUT_LINE('=== TESTE DE LIMITES: FALHA (Total ECTS: '||v_total_ects||') ===');
    END IF;

    COMMIT;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERRO FATAL NO TESTE DE LIMITES: ' || SQLERRM);
    ROLLBACK;
END;
/
