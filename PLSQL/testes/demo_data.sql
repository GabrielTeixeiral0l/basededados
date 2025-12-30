-- =============================================================================
-- SCRIPT DE DEMONSTRAÇÃO: DADOS RICOS PARA APRESENTAÇÃO (ANTI-MUTAÇÃO)
-- Objetivo: Criar um cenário realista sem causar erros ORA-04091.
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_num_sfx    NUMBER := TRUNC(DBMS_RANDOM.VALUE(1000,9999));
    v_sufixo     VARCHAR2(10) := TO_CHAR(v_num_sfx);
    v_cur_id NUMBER; v_uc_id NUMBER; v_doc_id NUMBER; v_tur_id NUMBER;
    v_tc_id NUMBER; v_ta_id  NUMBER; v_sal_id NUMBER;
    v_tav_id NUMBER; v_ava_id NUMBER;
    
    v_est1_id NUMBER; v_est2_id NUMBER; v_est3_id NUMBER; v_est4_id NUMBER;
    v_mat1_id NUMBER; v_ins1_id NUMBER;
    v_mat2_id NUMBER; v_ins2_id NUMBER;
    v_mat3_id NUMBER; v_ins3_id NUMBER;
    v_mat4_id NUMBER; v_ins4_id NUMBER;

    v_aul_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== GERANDO DADOS DE DEMONSTRAÇÃO (Cenário Realista) ===');

    -- 1. INFRAESTRUTURA
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('L_DEMO_'||v_sufixo, 1500) RETURNING id INTO v_tc_id;
    INSERT INTO tipo_aula (nome) VALUES ('T_'||v_sufixo) RETURNING id INTO v_ta_id;
    INSERT INTO sala (nome, capacidade) VALUES ('S_DEMO_'||v_sufixo, 50) RETURNING id INTO v_sal_id;
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) VALUES ('Aval_'||v_sufixo, '0', '0', '0') RETURNING id INTO v_tav_id;

    -- 2. CURSO E UC
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id)
    VALUES ('Engenharia '||v_sufixo, 'E'||v_sufixo, 'Demo', 3, 180, 50, v_tc_id) RETURNING id INTO v_cur_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
    VALUES ('BD Avançadas '||v_sufixo, 'BDA'||v_sufixo, 20, 20) RETURNING id INTO v_uc_id;

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca)
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', 25);

    -- 3. DOCENTE E TURMA
    INSERT INTO docente (nome, data_contratacao, nif, telemovel, email, status)
    VALUES ('Prof. '||v_sufixo, SYSDATE-30, '2'||LPAD(v_sufixo, 8, '0'), '96'||LPAD(v_sufixo, 7, '0'), 'p'||v_sufixo||'@d.pt', '1') RETURNING id INTO v_doc_id;

    -- Habilitar Docente para a UC (Necessário para TRG_VAL_TURMA)
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
    VALUES (v_uc_id, v_doc_id, 'Regente', '1');

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('T_A_'||v_sufixo, '25', v_uc_id, 30, v_doc_id) RETURNING id INTO v_tur_id;

    -- 4. ALUNOS E INSCRIÇÕES (STATUS '0' para evitar mutating table)
    -- Aluno 1
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Exemplar '||v_sufixo, '1'||LPAD(v_sufixo, 8, '1'), '1'||LPAD(v_sufixo, 7, '1')||'ZZ1', TO_DATE('2000-01-01','YYYY-MM-DD'), '91'||LPAD(v_sufixo, 7, '1'), 'a1'||v_sufixo||'@d.pt') RETURNING id INTO v_est1_id;
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est1_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat1_id;
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_tur_id, v_mat1_id, SYSDATE, '0') RETURNING id INTO v_ins1_id;

    -- Aluno 2
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Seguro '||v_sufixo, '1'||LPAD(v_sufixo, 8, '2'), '1'||LPAD(v_sufixo, 7, '2')||'ZZ2', TO_DATE('2000-01-01','YYYY-MM-DD'), '91'||LPAD(v_sufixo, 7, '2'), 'a2'||v_sufixo||'@d.pt') RETURNING id INTO v_est2_id;
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est2_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat2_id;
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_tur_id, v_mat2_id, SYSDATE, '0') RETURNING id INTO v_ins2_id;

    -- Aluno 3
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Risco '||v_sufixo, '1'||LPAD(v_sufixo, 8, '3'), '1'||LPAD(v_sufixo, 7, '3')||'ZZ3', TO_DATE('2000-01-01','YYYY-MM-DD'), '91'||LPAD(v_sufixo, 7, '3'), 'a3'||v_sufixo||'@d.pt') RETURNING id INTO v_est3_id;
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est3_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat3_id;
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_tur_id, v_mat3_id, SYSDATE, '0') RETURNING id INTO v_ins3_id;

    -- Aluno 4
    INSERT INTO estudante (nome, nif, cc, data_nascimento, telemovel, email) 
    VALUES ('Abandono '||v_sufixo, '1'||LPAD(v_sufixo, 8, '4'), '1'||LPAD(v_sufixo, 7, '4')||'ZZ4', TO_DATE('2000-01-01','YYYY-MM-DD'), '91'||LPAD(v_sufixo, 7, '4'), 'a4'||v_sufixo||'@d.pt') RETURNING id INTO v_est4_id;
    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas) 
    VALUES (v_cur_id, v_est4_id, 'Ativa', 2025, 10) RETURNING id INTO v_mat4_id;
    INSERT INTO inscricao (turma_id, matricula_id, data, status) VALUES (v_tur_id, v_mat4_id, SYSDATE, '0') RETURNING id INTO v_ins4_id;

    -- 5. GERAR 10 AULAS (Inscrições '0' -> Sem erro de mutação)
    FOR i IN 1..10 LOOP
        INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
        VALUES (TRUNC(SYSDATE)-i, TRUNC(SYSDATE)+8/24, TRUNC(SYSDATE)+10/24, 'Aula '||i, v_ta_id, v_sal_id, v_tur_id)
        RETURNING id INTO v_aul_id;

        -- Inserir presenças manualmente
        INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins1_id, v_aul_id, '1', '1');
        
        IF i <= 8 THEN INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins2_id, v_aul_id, '1', '1');
        ELSE INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins2_id, v_aul_id, '0', '1'); END IF;

        IF i <= 7 THEN INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins3_id, v_aul_id, '1', '1');
        ELSE INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins3_id, v_aul_id, '0', '1'); END IF;

        INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins4_id, v_aul_id, '0', '1');
    END LOOP;

    -- Ativar inscrições
    UPDATE inscricao SET status = '1' WHERE turma_id = v_tur_id;

    -- 6. AVALIAÇÕES E NOTAS
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Teste Final', SYSDATE, SYSDATE, 1, 1, v_tur_id, v_tav_id) RETURNING id INTO v_ava_id;

    INSERT INTO nota (inscricao_id, avaliacao_id, nota, status) VALUES (v_ins1_id, v_ava_id, 19, '1');
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, status) VALUES (v_ins2_id, v_ava_id, 14, '1');
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, status) VALUES (v_ins3_id, v_ava_id, 10, '1');
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, status) VALUES (v_ins4_id, v_ava_id, 0, '1');

    UPDATE inscricao SET nota_final = 19 WHERE id = v_ins1_id;
    UPDATE inscricao SET nota_final = 14 WHERE id = v_ins2_id;
    UPDATE inscricao SET nota_final = 10 WHERE id = v_ins3_id;
    UPDATE inscricao SET nota_final = 0 WHERE id = v_ins4_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Dados gerados com sucesso. Turma: ' || v_tur_id);
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERRO NO DEMO: ' || SQLERRM);
END;
/