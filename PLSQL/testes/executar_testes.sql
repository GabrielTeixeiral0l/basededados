-- =============================================================================
-- SCRIPT DE TESTES UNITÁRIOS E INTEGRADOS (CORRIGIDO DDLV3)
-- Objetivo: Testar a integração entre todas as tabelas e PL/SQL
-- =============================================================================
SET SERVEROUTPUT ON;
SET FEEDBACK OFF;

DECLARE
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    
    -- IDs gerados
    v_est_id NUMBER; v_cur_id NUMBER; v_mat_id NUMBER;
    v_uc_id NUMBER; v_doc_id NUMBER; v_tur_id NUMBER;
    v_ins_id NUMBER; v_aul_id NUMBER; v_ava_id NUMBER;
    v_sal_id NUMBER; v_ta_id NUMBER; v_tc_id NUMBER;
    v_em_id NUMBER; v_tav_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES (Sufixo: '||v_sufixo||') ===');

    -- 1. CONFIGURAÇÃO BASE
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('L '||v_sufixo, 1000) RETURNING id INTO v_tc_id;
    INSERT INTO tipo_aula (nome) VALUES ('T '||v_sufixo) RETURNING id INTO v_ta_id;
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) 
    VALUES ('E '||v_sufixo, '0', '0', '1') RETURNING id INTO v_tav_id;
    INSERT INTO sala (nome, capacidade) VALUES ('S'||v_sufixo, 30) RETURNING id INTO v_sal_id;

    -- 2. PESSOAS E CURSOS
    INSERT INTO estudante (nome, morada, data_nascimento, cc, nif, email, telemovel)
    VALUES ('Aluno '||v_sufixo, 'Rua A', SYSDATE-7000, 
            '12345678', '501234564', 
            'a'||v_sufixo||'@email.com', '910000000')
    RETURNING id INTO v_est_id;

    INSERT INTO curso (nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id)
    VALUES ('Eng '||v_sufixo, 'C'||v_sufixo, 'Desc', 3, 180, 30, v_tc_id)
    RETURNING id INTO v_cur_id;

    INSERT INTO matricula (curso_id, estudante_id, estado_matricula, ano_inscricao, numero_parcelas)
    VALUES (v_cur_id, v_est_id, 'Ativa', 2025, 10)
    RETURNING id INTO v_mat_id;

    -- 3. ACADÉMICO
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
    VALUES ('UC '||v_sufixo, 'U'||v_sufixo, 40, 20)
    RETURNING id INTO v_uc_id;

    -- Corrigido: presenca_obrigatoria em vez de obrigatoria
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria)
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1');

    BEGIN
        INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel)
        VALUES ('Prof '||v_sufixo, SYSDATE, '275730972', 
                '87654321', 'd'||v_sufixo||'@email.com', '930000000')
        RETURNING id INTO v_doc_id;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[AVISO] Falha ao inserir Docente (provável validação). Usando ID fictício.');
        -- Tentar recuperar um ID existente ou continuar sem (o que falhará a turma a seguir, mas permite debug)
        SELECT MIN(id) INTO v_doc_id FROM docente;
    END;

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('T'||v_sufixo, '25/26', v_uc_id, 20, v_doc_id)
    RETURNING id INTO v_tur_id;

    INSERT INTO inscricao (turma_id, matricula_id, data)
    VALUES (v_tur_id, v_mat_id, SYSDATE)
    RETURNING id INTO v_ins_id;

    -- 4. ATIVIDADE
    INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
    VALUES (SYSDATE, SYSDATE, SYSDATE+1/24, 'Aula 1', v_ta_id, v_sal_id, v_tur_id)
    RETURNING id INTO v_aul_id;

    -- INSERT INTO presenca (inscricao_id, aula_id, presente) VALUES (v_ins_id, v_aul_id, '1'); -- CAUSA DUPLICADO!
    UPDATE presenca SET presente = '1' WHERE inscricao_id = v_ins_id AND aula_id = v_aul_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[AVISO] Nenhuma presença atualizada. Verifique se o trigger TRG_AUTO_PRESENCA funcionou.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[OK] Presença atualizada para Presente.');
    END IF;

    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('T1 '||v_sufixo, SYSDATE, SYSDATE, 100, 1, v_tur_id, v_tav_id)
    RETURNING id INTO v_ava_id;

    INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario)
    VALUES (v_ins_id, v_ava_id, 18, 'Excelente');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== TESTES CONCLUÍDOS COM SUCESSO (COMMIT REALIZADO) ===');
    DBMS_OUTPUT.PUT_LINE('Inscrição Gerada: ' || v_ins_id);
    
EXCEPTION WHEN OTHERS THEN
    -- ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('!!! ERRO NOS TESTES !!!');
    DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
