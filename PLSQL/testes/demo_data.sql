-- =============================================================================
-- SCRIPT DE DEMONSTRAÇÃO: DADOS RICOS PARA APRESENTAÇÃO
-- Objetivo: Criar um cenário realista com turma, aulas e assiduidade variada.
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sufixo     VARCHAR2(10) := 'DEMO_'||TO_CHAR(SYSTIMESTAMP, 'MI');
    
    -- IDs
    v_cur_id NUMBER; v_uc_id NUMBER; v_doc_id NUMBER; v_tur_id NUMBER;
    v_em_id  NUMBER; v_tc_id NUMBER; v_ta_id  NUMBER; v_sal_id NUMBER;
    v_tav_id NUMBER; v_ava_id NUMBER;
    
    -- Alunos
    v_est1_id NUMBER; -- 0% Faltas (Exemplar)
    v_est2_id NUMBER; -- 20% Faltas (Seguro)
    v_est3_id NUMBER; -- 30% Faltas (Em Risco/Alerta)
    v_est4_id NUMBER; -- 100% Faltas (Abandono)
    
    -- Matrículas e Inscrições
    v_mat1_id NUMBER; v_ins1_id NUMBER;
    v_mat2_id NUMBER; v_ins2_id NUMBER;
    v_mat3_id NUMBER; v_ins3_id NUMBER;
    v_mat4_id NUMBER; v_ins4_id NUMBER;

    -- Auxiliares
    v_aul_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== GERANDO DADOS DE DEMONSTRAÇÃO (Cenário Realista) ===');

    -- 1. INFRAESTRUTURA
    -- Garantir tipos básicos
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('Licenciatura Demo', 1500) RETURNING id INTO v_tc_id;
    INSERT INTO tipo_aula (nome) VALUES ('Teórica') RETURNING id INTO v_ta_id;
    INSERT INTO sala (nome, capacidade) VALUES ('Sala Demo', 50) RETURNING id INTO v_sal_id;
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) VALUES ('Teste Escrito', '0', '0', '0') RETURNING id INTO v_tav_id;

    -- 2. CURSO E UC
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id)
    VALUES ('Engenharia de Dados '||v_sufixo, 'ED'||v_sufixo, 'Curso Demo', 3, 180, 50, v_tc_id)
    RETURNING id INTO v_cur_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
    VALUES ('Bases de Dados Avançadas', 'BDA'||v_sufixo, 20, 20) -- Total 40h
    RETURNING id INTO v_uc_id;

    -- Associar UC ao Curso (Obrigatória presença)
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca)
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', 25); -- Limite de 25% de faltas

    -- 3. DOCENTE E TURMA
    INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel)
    VALUES ('Prof. Demonstrador', SYSDATE, SUBSTR(TO_CHAR(SYSTIMESTAMP,'FF'),1,9), 'CC'||v_sufixo, 'prof@demo.pt', '912345678')
    RETURNING id INTO v_doc_id;

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('TURMA_A', '25/26', v_uc_id, 30, v_doc_id)
    RETURNING id INTO v_tur_id;

    -- 4. ALUNOS E INSCRIÇÕES
    -- Aluno 1 (Exemplar)
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Aluno Exemplar', SUBSTR(v_sufixo||'1',1,9), 'CC1'||v_sufixo, SYSDATE-7000, '910000001', 'a1@demo.pt') 
    RETURNING id INTO v_est1_id;
    
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est1_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat1_id;
    
    INSERT INTO inscricao (turma_id, matricula_id, data) 
    VALUES (v_tur_id, v_mat1_id, SYSDATE) RETURNING id INTO v_ins1_id;

    -- Aluno 2 (Seguro - 20% faltas)
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Aluno Seguro', SUBSTR(v_sufixo||'2',1,9), 'CC2'||v_sufixo, SYSDATE-7000, '910000002', 'a2@demo.pt') 
    RETURNING id INTO v_est2_id;
    
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est2_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat2_id;
    
    INSERT INTO inscricao (turma_id, matricula_id, data) 
    VALUES (v_tur_id, v_mat2_id, SYSDATE) RETURNING id INTO v_ins2_id;

    -- Aluno 3 (Risco - 30% faltas)
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Aluno Risco', SUBSTR(v_sufixo||'3',1,9), 'CC3'||v_sufixo, SYSDATE-7000, '910000003', 'a3@demo.pt') 
    RETURNING id INTO v_est3_id;
    
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est3_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat3_id;
    
    INSERT INTO inscricao (turma_id, matricula_id, data) 
    VALUES (v_tur_id, v_mat3_id, SYSDATE) RETURNING id INTO v_ins3_id;

    -- Aluno 4 (Abandono - 100% faltas)
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Aluno Fantasma', SUBSTR(v_sufixo||'4',1,9), 'CC4'||v_sufixo, SYSDATE-7000, '910000004', 'a4@demo.pt') 
    RETURNING id INTO v_est4_id;
    
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est4_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat4_id;
    
    INSERT INTO inscricao (turma_id, matricula_id, data) 
    VALUES (v_tur_id, v_mat4_id, SYSDATE) RETURNING id INTO v_ins4_id;

    -- 5. GERAR 10 AULAS E PRESENÇAS
    -- Cenário: 10 aulas no total.
    FOR i IN 1..10 LOOP
        INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
        VALUES (SYSDATE + i, SYSDATE + i, SYSDATE + i + (2/24), 'Aula Demo '||i, v_ta_id, v_sal_id, v_tur_id)
        RETURNING id INTO v_aul_id;

        -- O Trigger TRG_AUTO_PRESENCA_AULA já cria os registos de presença como '0' (Falta) para todos.
        -- Agora vamos atualizar para '1' (Presente) conforme o perfil.

        -- Aluno 1 (Sempre presente)
        UPDATE presenca SET presente = '1' WHERE inscricao_id = v_ins1_id AND aula_id = v_aul_id;

        -- Aluno 2 (Falta nas aulas 9 e 10)
        IF i <= 8 THEN
            UPDATE presenca SET presente = '1' WHERE inscricao_id = v_ins2_id AND aula_id = v_aul_id;
        END IF;

        -- Aluno 3 (Falta nas aulas 8, 9 e 10)
        IF i <= 7 THEN
            UPDATE presenca SET presente = '1' WHERE inscricao_id = v_ins3_id AND aula_id = v_aul_id;
        END IF;

        -- Aluno 4 (Nunca vem) - Mantém '0'
    END LOOP;

    -- 6. CRIAR AVALIAÇÃO E NOTAS VARIADAS
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Teste Final', SYSDATE+11, SYSDATE+11, 100, 1, v_tur_id, v_tav_id)
    RETURNING id INTO v_ava_id;

    INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario) VALUES (v_ins1_id, v_ava_id, 19, 'Excelente');
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario) VALUES (v_ins2_id, v_ava_id, 14, 'Bom');
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario) VALUES (v_ins3_id, v_ava_id, 10, 'Suficiente');
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario) VALUES (v_ins4_id, v_ava_id, 0, 'Faltou');

    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Dados gerados com sucesso.');
    DBMS_OUTPUT.PUT_LINE('Turma criada: ' || v_tur_id);
    DBMS_OUTPUT.PUT_LINE('Consulte a vista: SELECT * FROM VW_ALERTA_ASSIDUIDADE WHERE turma_id = ' || v_tur_id);

EXCEPTION WHEN OTHERS THEN
    -- ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERRO: ' || SQLERRM);
END;
/
