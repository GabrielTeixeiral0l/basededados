-- =============================================================================
-- TESTE UNITÁRIO: REGRAS ACADÉMICAS DE INSCRIÇÃO (Compatibilidade Total DDLv3)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100,999)));
    v_est_id NUMBER := 9000 + v_sfx;
    v_cur_id NUMBER := 8000 + v_sfx;
    v_uc_id  NUMBER := 7000 + v_sfx;
    v_mat_id NUMBER := 6000 + v_sfx;
    v_tur_a  NUMBER := 5000 + v_sfx;
    v_tur_b  NUMBER := 4000 + v_sfx;
    v_doc_id NUMBER := 3000 + v_sfx;
    v_tc_id  NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE DE REGRAS DE INSCRICAO (18d) ===');

    -- 1. SETUP DE DADOS BASE (Respeitando DDLv3)
    BEGIN
        -- 1.1. Obter Tipo de Curso existente
        SELECT MIN(id) INTO v_tc_id FROM tipo_curso;
        IF v_tc_id IS NULL THEN
            v_tc_id := 1;
            INSERT INTO tipo_curso (id, nome, valor_propinas) VALUES (v_tc_id, 'Licenciatura', 1000);
        END IF;

        -- 1.2. Criar Docente (Tabela base no DDLv3)
        INSERT INTO docente (id, nome, data_contratacao, nif, email, telemovel) 
        VALUES (v_doc_id, 'Professor Teste', SYSDATE, '275730972', 'prof@escola.pt', '910000000');

        -- 1.3. Criar Curso e UC
        INSERT INTO curso (id, nome, codigo, descricao, duracao, ects, tipo_curso_id) 
        VALUES (v_cur_id, 'Engenharia Teste', 'ENG'||v_sfx, 'Desc', 3, 180, v_tc_id);
        
        INSERT INTO unidade_curricular (id, nome, codigo, horas_teoricas, horas_praticas) 
        VALUES (v_uc_id, 'Base de Dados II', 'BD2'||v_sfx, 30, 30);

        -- 1.4. Ligar UC al Curso
        INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca) 
        VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', 75);

        -- Habilitar Docente para a UC
        INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
        VALUES (v_uc_id, v_doc_id, 'Regente', '1');

        -- 1.5. Criar Estudante e Matrícula
        INSERT INTO estudante (id, nome, cc, nif, data_nascimento, email, telemovel) 
        VALUES (v_est_id, 'Aluno Teste', '12345678', '275730972', TO_DATE('2000-01-01','YYYY-MM-DD'), 'aluno@teste.pt', '920000000');
        
        INSERT INTO matricula (id, estudante_id, curso_id, ano_inscricao, estado_matricula, numero_parcelas) 
        VALUES (v_mat_id, v_est_id, v_cur_id, 2025, 'Ativa', 10);

        -- 1.6. Criar Turmas
        INSERT INTO turma (id, nome, ano_letivo, unidade_curricular_id, docente_id) 
        VALUES (v_tur_a, 'Turma A', '2025', v_uc_id, v_doc_id);
        
        INSERT INTO turma (id, nome, ano_letivo, unidade_curricular_id, docente_id) 
        VALUES (v_tur_b, 'Turma B', '2025', v_uc_id, v_doc_id);

        -- ---------------------------------------------------------------------
        -- 2. EXECUÇÃO DOS TESTES
        -- ---------------------------------------------------------------------
        
        -- TESTE 1: Inscrição válida
        BEGIN
            INSERT INTO inscricao (id, turma_id, matricula_id, data) 
            VALUES (seq_inscricao.NEXTVAL, v_tur_a, v_mat_id, SYSDATE);
            DBMS_OUTPUT.PUT_LINE('[OK] Inscricao valida realizada.');
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[FALHA] Inscricao valida rejeitada: ' || SQLERRM);
        END;

        -- TESTE 2: Bloqueio de Duplicados (Mesma UC em turmas diferentes)
        BEGIN
            INSERT INTO inscricao (id, turma_id, matricula_id, data) 
            VALUES (seq_inscricao.NEXTVAL, v_tur_b, v_mat_id, SYSDATE);
            DBMS_OUTPUT.PUT_LINE('[FALHA] Permitiu inscricao duplicada na mesma UC.');
        EXCEPTION WHEN OTHERS THEN
            -- Esperamos que a nossa Trigger de Integridade bloqueie isto
            DBMS_OUTPUT.PUT_LINE('[OK] Bloqueou duplicado corretamente: ' || SQLERRM);
        END;

    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('!!! ERRO CRITICO NO SETUP: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END;

    DBMS_OUTPUT.PUT_LINE('=== FIM DOS TESTES DE INSCRICAO (ROLLBACK) ===');
    ROLLBACK;
END;
/