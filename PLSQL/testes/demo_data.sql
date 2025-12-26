-- =============================================================================
-- SCRIPT DE DADOS DE DEMONSTRAÇÃO (PERSISTENTE)
-- Objetivo: Criar dados reais para permitir consulta manual às vistas
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sufixo VARCHAR2(5) := 'DEMO';
    v_curso_id NUMBER;
    v_uc_id NUMBER;
    v_doc_id NUMBER;
    v_turma_id NUMBER;
    v_est_id NUMBER;
    v_mat_id NUMBER;
    v_ins_id NUMBER;
    v_sala_id NUMBER;
    v_ta_id NUMBER;
    v_em_id NUMBER;
    v_tc_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Criando Dados de Demonstração ---');

    -- 1. Configurações Básicas
    -- Verificar se já existem, senão criar
    BEGIN SELECT id INTO v_em_id FROM estado_matricula WHERE ROWNUM=1; EXCEPTION WHEN NO_DATA_FOUND THEN 
        INSERT INTO estado_matricula (nome) VALUES ('Ativo') RETURNING id INTO v_em_id; END;
        
    BEGIN SELECT id INTO v_tc_id FROM tipo_curso WHERE ROWNUM=1; EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('Licenciatura', 1000) RETURNING id INTO v_tc_id; END;
        
    BEGIN SELECT id INTO v_ta_id FROM tipo_aula WHERE ROWNUM=1; EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO tipo_aula (nome) VALUES ('Teorica') RETURNING id INTO v_ta_id; END;
        
    BEGIN SELECT id INTO v_sala_id FROM sala WHERE ROWNUM=1; EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO sala (nome, capacidade) VALUES ('SALA_DEMO', 30) RETURNING id INTO v_sala_id; END;

    -- 2. Curso e UC
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id)
    VALUES ('Curso Demo', 'CD_'||v_sufixo, 'Curso para teste de vistas', 3, 180, 30, v_tc_id)
    RETURNING id INTO v_curso_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
    VALUES ('UC Demo', 'UCD', 60, 30) RETURNING id INTO v_uc_id;

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria)
    VALUES (v_curso_id, v_uc_id, 1, 1, 6, '1');

    -- 3. Docente e Turma
    INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel)
    VALUES ('Docente Demo', SYSDATE, '100000000', '000000000ZZ4', 'doc@demo.com', '910000000')
    RETURNING id INTO v_doc_id;

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('T_DEMO', '25/26', v_uc_id, 25, v_doc_id)
    RETURNING id INTO v_turma_id;

    -- 4. Aluno e Inscrição
    INSERT INTO estudante (nome, morada, data_nascimento, cc, nif, email, telemovel)
    VALUES ('Aluno Faltoso', 'Rua Demo', TO_DATE('2000-01-01','YYYY-MM-DD'), 
            '111111111ZZ1', '200000000', 'aluno@demo.com', '960000000')
    RETURNING id INTO v_est_id;

    INSERT INTO matricula (curso_id, estudante_id, estado_matricula_id, ano_inscricao, numero_parcelas)
    VALUES (v_curso_id, v_est_id, v_em_id, 2025, 10)
    RETURNING id INTO v_mat_id;

    INSERT INTO inscricao (turma_id, matricula_id, data, nota_final)
    VALUES (v_turma_id, v_mat_id, SYSDATE, 12)
    RETURNING id INTO v_ins_id;

    -- 5. Gerar 10 Aulas (O trigger vai marcar falta '0' automaticamente na tabela presenca)
    FOR i IN 1..10 LOOP
        INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
        VALUES (SYSDATE - i, TO_DATE('09:00','HH24:MI'), TO_DATE('11:00','HH24:MI'), 'Aula Demo '||i, v_ta_id, v_sala_id, v_turma_id);
    END LOOP;

    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Dados inseridos e gravados (COMMIT).');
    DBMS_OUTPUT.PUT_LINE('Pode agora consultar a vista: SELECT * FROM VW_ALERTA_ASSIDUIDADE;');
END;
/
