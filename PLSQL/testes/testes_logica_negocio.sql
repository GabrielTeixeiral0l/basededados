-- =============================================================================
-- TESTE UNITÁRIO: LÓGICA DE NEGÓCIO E FINANCEIRA (Corrigido V3)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999))); -- 4 digitos
    v_est_id NUMBER; v_cur_id NUMBER; v_mat_id NUMBER; v_par_id NUMBER;
    v_uc_id NUMBER; v_tur_id NUMBER; v_ins_id NUMBER;
    v_av_pai NUMBER; v_av_f1 NUMBER; v_av_f2 NUMBER;
    v_nota_final NUMBER;
    v_estado CHAR(1);
    v_doc_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES DE LÓGICA DE NEGÓCIO ===');

    -- Garantir docente (Criar se nao existir ou usar um novo para evitar conflitos)
    INSERT INTO docente (nome, data_contratacao, nif, email, telemovel, status)
    VALUES ('Docente Logica '||v_sfx, SYSDATE-100, '1'||v_sfx||'9999', 'doc'||v_sfx||'@t.pt', '96'||v_sfx||'0000', '1')
    RETURNING id INTO v_doc_id;

    -- Setup: Criar Aluno (Telemovel = 9 + 8 digitos)
    -- NIF = 9 digitos
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel, status) 
    VALUES ('Aluno Logica '||v_sfx, '2'||v_sfx||'1111', '1'||v_sfx||'222', TO_DATE('1990-01-01','YYYY-MM-DD'), 'a'||v_sfx||'@l.pt', '91'||v_sfx||'0000', '1') 
    RETURNING id INTO v_est_id;

    -- Setup: Curso
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id, status) 
    VALUES ('Curso Logica', 'CL'||v_sfx, 'Desc', 3, 180, 1, '1') RETURNING id INTO v_cur_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status)
    VALUES ('UC Logica', 'UL'||v_sfx, 10, 10, '1') RETURNING id INTO v_uc_id;

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca, status)
    VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', 75, '1');

    -- Habilitar Docente para a UC
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
    VALUES (v_uc_id, v_doc_id, 'Regente', '1');

    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status)
    VALUES ('TL'||v_sfx, '2025', v_uc_id, v_doc_id, '1') RETURNING id INTO v_tur_id;

    -- 1. Testando Plano de Pagamentos (Trigger Automático)
    INSERT INTO matricula (estudante_id, curso_id, ano_inscricao, estado_matricula, numero_parcelas, status) 
    VALUES (v_est_id, v_cur_id, 2025, 'Ativa', 10, '1') RETURNING id INTO v_mat_id;

    DECLARE v_count NUMBER; BEGIN
        SELECT COUNT(*) INTO v_count FROM parcela_propina WHERE matricula_id = v_mat_id;
        IF v_count = 10 THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Plano financeiro gerado automaticamente.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] Plano nao gerado corretamente.');
        END IF;
    END;

    -- 2. Testando Agregação de Notas
    DBMS_OUTPUT.PUT_LINE('1. Testando Agregação de Notas (Exemplos Variados)...');
    
    INSERT INTO inscricao (turma_id, matricula_id, data, status) 
    VALUES (v_tur_id, v_mat_id, SYSDATE, '1') RETURNING id INTO v_ins_id;

    -- Criar Tipo de Avaliacao que permite filhos se não houver um
    DECLARE v_ta_id NUMBER; BEGIN
        BEGIN
            SELECT id INTO v_ta_id FROM tipo_avaliacao WHERE permite_filhos = '1' AND status = '1' AND ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos, status)
            VALUES ('Hibrida '||v_sfx, '1', '1', '1', '1') RETURNING id INTO v_ta_id;
        END;
        
        INSERT INTO avaliacao (titulo, data, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
        VALUES ('Pai A', SYSDATE, 0.4, 1, v_tur_id, v_ta_id, '1') RETURNING id INTO v_av_pai;

        INSERT INTO avaliacao (titulo, data, peso, max_alunos, turma_id, tipo_avaliacao_id, avaliacao_pai_id, status)
        VALUES ('Filho 1', SYSDATE, 0.5, 1, v_tur_id, v_ta_id, v_av_pai, '1') RETURNING id INTO v_av_f1;

        INSERT INTO avaliacao (titulo, data, peso, max_alunos, turma_id, tipo_avaliacao_id, avaliacao_pai_id, status)
        VALUES ('Filho 2', SYSDATE, 0.5, 1, v_tur_id, v_ta_id, v_av_pai, '1') RETURNING id INTO v_av_f2;
    END;

    -- Lançar Notas
    INSERT INTO nota (inscricao_id, avaliacao_id, nota) VALUES (v_ins_id, v_av_f1, 14);
    INSERT INTO nota (inscricao_id, avaliacao_id, nota) VALUES (v_ins_id, v_av_f2, 18);

    SELECT nota INTO v_nota_final FROM nota WHERE inscricao_id = v_ins_id AND avaliacao_id = v_av_pai;
    IF v_nota_final = 16 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Agregação de Notas correta: 16');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Nota do pai incorreta: ' || v_nota_final);
    END IF;

    -- 3. Liquidação
    SELECT id INTO v_par_id FROM parcela_propina WHERE matricula_id = v_mat_id AND ROWNUM = 1;
    PKG_TESOURARIA.PRC_LIQUIDAR_PARCELA(v_par_id, SYSDATE);
    SELECT estado INTO v_estado FROM parcela_propina WHERE id = v_par_id;
    IF v_estado = '1' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Parcela liquidada com sucesso.');
    END IF;

    ROLLBACK;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO NO BLOCO 12: ' || SQLERRM);
    ROLLBACK;
END;
/
