-- =============================================================================
-- TESTE INTEGRADO: FLUXO DE NOTAS ATÉ MÉDIA GERAL (Ponta-a-Ponta)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx       VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999)));
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
    v_tav_id    NUMBER;
    v_aval1_id  NUMBER;
    v_aval2_id  NUMBER;
    v_media_final NUMBER;
    v_media_esperada NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE INTEGRADO: NOTAS -> MÉDIA GERAL ===');

    -- 1. SETUP DE DADOS
    INSERT INTO docente (nome, nif, email, telemovel, data_contratacao, status)
    VALUES ('Doc Integ '||v_sfx, '4'||v_sfx||'4444', 'di'||v_sfx||'@t.pt', '96'||v_sfx||'444', SYSDATE-30, '1') RETURNING id INTO v_doc_id;
    
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('Tipo Demo'||v_sfx, 1000) RETURNING id INTO v_cur_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id) 
    VALUES ('Curso Integ '||v_sfx, 'CI'||v_sfx, 'Desc', 3, 180, v_cur_id) RETURNING id INTO v_cur_id;

    -- UC 1: 10 ECTS
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('UC1 '||v_sfx, 'U1'||v_sfx, 30, 30) RETURNING id INTO v_uc1_id;
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca) 
    VALUES (v_cur_id, v_uc1_id, 1, 1, 10, '1', 75);

    -- UC 2: 20 ECTS
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('UC2 '||v_sfx, 'U2'||v_sfx, 30, 30) RETURNING id INTO v_uc2_id;
    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca) 
    VALUES (v_cur_id, v_uc2_id, 1, 1, 20, '1', 75);

    -- Habilitar Docente para as UCs
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status) VALUES (v_uc1_id, v_doc_id, 'Regente', '1');
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status) VALUES (v_uc2_id, v_doc_id, 'Docente', '1');

    -- Turmas (Sem aulas para evitar Mutating Table no trigger de presenças)
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id) 
    VALUES ('T1'||v_sfx, '2025', v_uc1_id, v_doc_id) RETURNING id INTO v_tur1_id;
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id) 
    VALUES ('T2'||v_sfx, '2025', v_uc2_id, v_doc_id) RETURNING id INTO v_tur2_id;

    -- Aluno e Matrícula
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel) 
    VALUES ('Aluno Integ '||v_sfx, '5'||v_sfx||'5555', '1'||v_sfx||'555', TO_DATE('2000-01-01','YYYY-MM-DD'), 'ai'||v_sfx||'@n.pt', '912345678') 
    RETURNING id INTO v_est_id;

    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas) 
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10) RETURNING id INTO v_mat_id;

    -- Inscrições
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur1_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins1_id;
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_tur2_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins2_id;

    -- Avaliações
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) VALUES ('Teste'||v_sfx, '0', '0', '0') RETURNING id INTO v_tav_id;
    
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Aval UC1', SYSDATE, SYSDATE, 1, 1, v_tur1_id, v_tav_id) RETURNING id INTO v_aval1_id;

    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
    VALUES ('Aval UC2', SYSDATE, SYSDATE, 1, 1, v_tur2_id, v_tav_id) RETURNING id INTO v_aval2_id;

    -- 2. LANÇAMENTO DE NOTAS PARCIAIS
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario) VALUES (v_ins1_id, v_aval1_id, 18, 'Muito Bom');
    INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario) VALUES (v_ins2_id, v_aval2_id, 12, 'Suficiente');

    DBMS_OUTPUT.PUT_LINE('>> Notas parciais lancadas: 18 (UC1) e 12 (UC2).');

    -- 3. FECHO DE PAUTA (Atualizar Inscrição)
    UPDATE inscricao SET nota_final = 18 WHERE id = v_ins1_id;
    UPDATE inscricao SET nota_final = 12 WHERE id = v_ins2_id;
    
    DBMS_OUTPUT.PUT_LINE('>> Pautas fechadas. Notas Finais atualizadas.');

    -- 4. VALIDAÇÃO
    -- Cálculo esperado: ((18 * 10) + (12 * 20)) / (10 + 20) = (180 + 240) / 30 = 420 / 30 = 14
    v_media_esperada := 14;
    
    SELECT media_geral INTO v_media_final FROM matricula WHERE id = v_mat_id;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Media Calculada pelo Sistema: ' || v_media_final);
    DBMS_OUTPUT.PUT_LINE('Media Esperada: ' || v_media_esperada);
    
    IF v_media_final = v_media_esperada THEN
        DBMS_OUTPUT.PUT_LINE('[OK] SUCESSO: A media foi calculada corretamente e propagada para a matricula.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] ERRO: A media nao corresponde ao esperado.');
    END IF;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== FIM DO TESTE INTEGRADO (ROLLBACK) ===');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO DE EXECUCAO: ' || SQLERRM);
    ROLLBACK;
END;
/